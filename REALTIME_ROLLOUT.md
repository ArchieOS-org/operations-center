# Realtime Rollout Plan

**Mission:** Convert 95% manual-fetch app to 100% realtime subscriptions.

**Current State:** Only AppState has realtime (activities table). Everything else is stale until manual refresh.

**Target State:** Every store listens to database changes. Zero manual refresh needed.

---

## PHASE 1: DATABASE FOUNDATION

### Task: Enable Realtime on Supabase Tables

**Documentation:**
- Context7: `/supabase/supabase` - Topic: "realtime publication replica identity postgres"
- Existing migration pattern: `supabase/migrations/`

**What to do:**
1. Create `supabase/migrations/023_enable_realtime.sql`
2. Add `REPLICA IDENTITY FULL` to 6 tables
3. Add tables to `supabase_realtime` publication

**Tables to enable:**
- `listings`
- `listing_notes`
- `activities`
- `agent_tasks`
- `listing_acknowledgments`
- `staff`

**SQL Pattern:**
```sql
ALTER TABLE table_name REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE table_name;
```

**Verification:**
- Deploy migration
- Check Supabase dashboard → Database → Replication
- AppState's existing subscription should start receiving updates

---

## PHASE 2: LISTING DETAIL STORE (CRITICAL PATH)

### Task 2.1: Add Realtime Subscription Properties

**Documentation:**
- Reference implementation: `apps/Operations Center/Operations Center/State/AppState.swift` (lines 136-174)
- Context7: `/supabase/supabase-swift` - Topic: "realtime channel subscription swift observable"

**File:** `apps/Operations Center/Operations Center/Features/ListingDetail/ListingDetailStore.swift`

**What to add:**
```swift
// After line 54 (realtorRepository property)
@ObservationIgnored
private var notesRealtimeTask: Task<Void, Never>?

@ObservationIgnored
private var activitiesRealtimeTask: Task<Void, Never>?

@ObservationIgnored
private var supabase: SupabaseClient

// Track note IDs for deduplication
private var noteIds: Set<String> = []
```

**Update init to inject SupabaseClient:**
```swift
init(
    listingId: String,
    listingRepository: ListingRepositoryClient,
    noteRepository: ListingNoteRepositoryClient,
    taskRepository: TaskRepositoryClient,
    realtorRepository: RealtorRepositoryClient,
    supabase: SupabaseClient  // NEW
) {
    self.listingId = listingId
    self.listingRepository = listingRepository
    self.noteRepository = noteRepository
    self.taskRepository = taskRepository
    self.realtorRepository = realtorRepository
    self.supabase = supabase  // NEW
}
```

**Add deinit:**
```swift
deinit {
    notesRealtimeTask?.cancel()
    activitiesRealtimeTask?.cancel()
}
```

---

### Task 2.2: Implement Notes Realtime Subscription

**Documentation:**
- AppState pattern: lines 136-174
- Context7: `/supabase/supabase-swift` - Topic: "postgresChange filter realtime swift"

**File:** `apps/Operations Center/Operations Center/Features/ListingDetail/ListingDetailStore.swift`

**Add after `fetchListingData()` method:**
```swift
/// Setup realtime subscription for notes on this listing
private func setupNotesRealtime() async {
    notesRealtimeTask?.cancel()

    let channel = supabase.realtimeV2.channel("listing_\(listingId)_notes")

    notesRealtimeTask = Task { [weak self] in
        guard let self else { return }
        do {
            // CRITICAL: Configure stream BEFORE subscribing
            let stream = channel.postgresChange(AnyAction.self, table: "listing_notes")

            // Now subscribe to start receiving events
            try await channel.subscribeWithError()

            // Listen for changes - structured concurrency handles cancellation
            for await change in stream {
                await self.handleNotesChange(change)
            }
        } catch is CancellationError {
            return
        } catch {
            Logger.database.error("Notes realtime error: \(error.localizedDescription)")
        }
    }
}

/// Handle realtime note changes with deduplication
private func handleNotesChange(_ change: AnyAction) async {
    do {
        switch change {
        case .insert(let action):
            let newNote = try action.decodeRecord(as: ListingNote.self)
            // Only append if this listing AND not duplicate
            guard newNote.listingId == listingId else { return }
            guard !noteIds.contains(newNote.id) else { return }

            notes.append(newNote)
            noteIds.insert(newNote.id)
            notes.sort { $0.createdAt < $1.createdAt }

            Logger.database.info("Realtime: Added note \(newNote.id)")

        case .update(let action):
            let updatedNote = try action.decodeRecord(as: ListingNote.self)
            guard updatedNote.listingId == listingId else { return }

            if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                notes[index] = updatedNote
                Logger.database.info("Realtime: Updated note \(updatedNote.id)")
            }

        case .delete(let action):
            struct Payload: Decodable { let id: String }
            let payload = try action.decodeOldRecord(as: Payload.self)

            notes.removeAll { $0.id == payload.id }
            noteIds.remove(payload.id)

            Logger.database.info("Realtime: Deleted note \(payload.id)")
        }
    } catch {
        Logger.database.error("Failed to decode note change: \(error.localizedDescription)")
    }
}
```

**Update `fetchListingData()` to start subscription:**
```swift
// After line 148 (isLoading = false)
// Start realtime subscriptions AFTER initial load
await setupNotesRealtime()
await setupActivitiesRealtime()
```

---

### Task 2.3: Update Optimistic Note Creation for Deduplication

**Documentation:**
- Current implementation: lines 156-204
- Deduplication pattern from explore agent research

**File:** `apps/Operations Center/Operations Center/Features/ListingDetail/ListingDetailStore.swift`

**Update `createNoteInBackground()` method:**
```swift
/// Create note in background - replace optimistic version with server response
private func createNoteInBackground(tempId: String, content: String) async {
    do {
        let createdNote = try await noteRepository.createNote(listingId, content)

        // Replace temp note with server response
        if let index = notes.firstIndex(where: { $0.id == tempId }) {
            notes[index] = createdNote

            // Update ID tracking for deduplication
            noteIds.remove(tempId)
            noteIds.insert(createdNote.id)
        }
        pendingNoteIds.remove(tempId)

        Logger.database.info("Created note for listing \(self.listingId)")
    } catch {
        // Revert optimistic update
        notes.removeAll { $0.id == tempId }
        noteIds.remove(tempId)  // Clean up temp ID
        pendingNoteIds.remove(tempId)

        Logger.database.error("Failed to create note: \(error.localizedDescription)")
        errorMessage = "Failed to create note: \(error.localizedDescription)"
    }
}
```

**Update `submitNote()` to track IDs:**
```swift
// After line 175 (notes.append(optimisticNote))
noteIds.insert(tempId)  // Track temp ID
```

---

### Task 2.4: Implement Activities Realtime Subscription

**Documentation:**
- Same pattern as notes
- AppState reference: lines 136-174

**File:** `apps/Operations Center/Operations Center/Features/ListingDetail/ListingDetailStore.swift`

**Add after `setupNotesRealtime()` method:**
```swift
/// Setup realtime subscription for activities on this listing
private func setupActivitiesRealtime() async {
    activitiesRealtimeTask?.cancel()

    let channel = supabase.realtimeV2.channel("listing_\(listingId)_activities")

    activitiesRealtimeTask = Task { [weak self] in
        guard let self else { return }
        do {
            // CRITICAL: Configure stream BEFORE subscribing
            let stream = channel.postgresChange(AnyAction.self, table: "activities")

            // Now subscribe to start receiving events
            try await channel.subscribeWithError()

            // Listen for changes
            for await change in stream {
                await self.handleActivitiesChange(change)
            }
        } catch is CancellationError {
            return
        } catch {
            Logger.database.error("Activities realtime error: \(error.localizedDescription)")
        }
    }
}

/// Handle realtime activity changes - simple refresh strategy
private func handleActivitiesChange(_ change: AnyAction) async {
    Logger.database.info("Realtime: Activity change detected, refreshing...")

    // Simple approach: re-fetch all activities for this listing
    // More complex: decode individual changes and merge
    do {
        let allActivities = try await taskRepository.fetchActivities()
        activities = allActivities.map(\.task).filter { $0.listingId == listingId }

        Logger.database.info("Realtime: Refreshed \(self.activities.count) activities")
    } catch {
        Logger.database.error("Failed to refresh activities: \(error.localizedDescription)")
    }
}
```

---

### Task 2.5: Update ListingDetailView to Pass SupabaseClient

**Documentation:**
- Current init: lines 49-63
- Dependency injection pattern

**File:** `apps/Operations Center/Operations Center/Features/ListingDetail/ListingDetailView.swift`

**Update init:**
```swift
init(
    listingId: String,
    listingRepository: ListingRepositoryClient,
    noteRepository: ListingNoteRepositoryClient,
    taskRepository: TaskRepositoryClient,
    realtorRepository: RealtorRepositoryClient,
    supabase: SupabaseClient  // NEW
) {
    _store = State(initialValue: ListingDetailStore(
        listingId: listingId,
        listingRepository: listingRepository,
        noteRepository: noteRepository,
        taskRepository: taskRepository,
        realtorRepository: realtorRepository,
        supabase: supabase  // NEW
    ))
}
```

**Update preview (line 518):**
```swift
ListingDetailView(
    listingId: "listing_001",
    listingRepository: .preview,
    noteRepository: .preview,
    taskRepository: .preview,
    realtorRepository: .preview,
    supabase: .preview  // NEW
)
```

---

### Task 2.6: Find All Call Sites and Update

**What to do:**
1. Search for `ListingDetailView(` in codebase
2. Add `supabase:` parameter to each call site
3. Most likely in navigation/routing code

**Search command:**
```bash
grep -r "ListingDetailView(" apps/Operations\ Center/
```

---

## PHASE 3: REMAINING STORES (Week 2)

### Task 3.1: InboxStore Realtime

**Tables to subscribe:**
- `listing_acknowledgments` (filter: staff_id=current_user)
- `agent_tasks` (filter: status=OPEN OR assigned_staff_id=current_user)
- `activities` (filter: listing_id IN unacknowledged_listings)

**Pattern:** Copy ListingDetailStore subscription approach

---

### Task 3.2: AllListingsStore Realtime

**Tables to subscribe:**
- `listings` (all rows)
- `activities` (all rows, for category mapping)

**Pattern:** Copy ListingDetailStore subscription approach

---

### Task 3.3: AllTasksStore Realtime

**Tables to subscribe:**
- `agent_tasks` (filter: status=CLAIMED OR status=IN_PROGRESS)
- `activities` (filter: status=CLAIMED OR status=IN_PROGRESS)

**Pattern:** Copy ListingDetailStore subscription approach

---

### Task 3.4: MyTasksStore Realtime

**Tables to subscribe:**
- `agent_tasks` (filter: assigned_staff_id=current_user)

**Pattern:** Copy ListingDetailStore subscription approach

---

### Task 3.5: MyListingsStore Realtime

**Tables to subscribe:**
- `listings` (filter: assignee=current_user)
- `activities` (filter: listing_id IN my_listings)

**Pattern:** Copy ListingDetailStore subscription approach

---

## PHASE 4: CLEANUP (Week 3)

### Task 4.1: Remove Manual Refresh Patterns

**Files to update:**
- All view files with `.refreshable` modifiers
- All stores with `refresh()` methods that just call `fetch()`

**What to remove:**
```swift
.refreshable {
    await store.refresh()
}
```

**What to keep:**
```swift
.task {
    await store.fetchData()  // Initial load still needed
}
```

---

### Task 4.2: Remove Fetch Calls After Mutations

**Pattern to remove:**
```swift
func claimActivity(_ activity: Activity) async {
    // ... claim logic ...
    await fetchListingData()  // DELETE THIS - realtime handles it
}
```

**Realtime handles the update automatically.**

---

## VERIFICATION CHECKLIST

After each phase:

1. **Database realtime enabled?**
   - Check Supabase dashboard → Database → Replication
   - See tables in `supabase_realtime` publication

2. **Subscriptions working?**
   - Add log statements in `handleChange()` methods
   - Create/update/delete data in Supabase Studio
   - See logs fire in Xcode console

3. **Deduplication working?**
   - Submit optimistic note
   - Verify only ONE note appears (not temp + real)
   - Check noteIds Set has correct IDs

4. **Cleanup working?**
   - Navigate away from view
   - Check deinit cancels tasks
   - Verify no memory leaks

5. **Multi-user working?**
   - Open app in two simulators
   - Make change in one
   - See update in other (< 1 second)

---

## ROLLBACK PLAN

If realtime breaks:

1. **Keep migration** - Realtime enabled in DB is harmless
2. **Revert Swift changes** - Git revert to last stable commit
3. **Manual refresh still works** - Old pattern is still there

Realtime is additive, not destructive.

---

## DOCUMENTATION REFERENCES

**Context7 Topics:**
- `/supabase/supabase-swift` - "realtime channel subscription"
- `/supabase/supabase-swift` - "postgresChange filter"
- `/supabase/supabase` - "replica identity publication"

**Code References:**
- AppState.swift lines 136-174 (working realtime example)
- ListingDetailStore.swift lines 156-204 (optimistic updates)

**Supabase Docs:**
- https://supabase.com/docs/guides/realtime/postgres-changes
- https://supabase.com/docs/guides/realtime/subscriptions

---

## SUCCESS METRICS

**Before:**
- Manual refresh on every view
- Stale data until pull-to-refresh
- No collaborative features

**After:**
- Zero manual refresh needed
- Updates appear instantly (< 100ms)
- True collaborative real estate operations app

Ship realtime. Ship quality.
