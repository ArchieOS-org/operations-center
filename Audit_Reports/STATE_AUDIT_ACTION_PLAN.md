# State Management Refactor: Action Plan
**Priority:** CRITICAL  
**Effort:** 6-8 hours  
**Impact:** Eliminates 12 critical bugs

---

## What To Do

### Phase 1: Design (30 minutes)

Create a single `AppStore` that consolidates all state:

```swift
@Observable @MainActor
final class AppStore {
    // Authentication
    var currentUser: Supabase.User?
    var isAuthenticated: Bool = false
    
    // All tasks (source of truth)
    var allTasks: [Activity] = []
    var allListings: [Listing] = []
    var allRealtors: [Realtor] = []
    
    // User selections (UI state)
    var selectedTaskFilter: TaskFilter = .all
    var expandedTaskIds: Set<String> = []  // Multiple can be expanded
    
    // Loading state
    var isLoading = false
    var errorMessage: String?
    
    // Computed properties (filtered views)
    var inboxTasks: [Activity] { ... }
    var myTasks: [Activity] { ... }
    var myListings: [Listing] { ... }
}
```

### Phase 2: Delete Dead Code (30 minutes)

Remove:
- AppState.swift
- AuthenticationStore.swift
- InboxStore.swift
- MyTasksStore.swift
- MyListingsStore.swift
- AllTasksStore.swift
- AllListingsStore.swift
- ListingDetailStore.swift
- LogbookStore.swift
- TeamViewStore.swift
- MarketingTeamStore.swift
- AdminTeamStore.swift
- AgentDetailStore.swift

(13 files, ~2,000 lines of complexity deleted)

### Phase 3: Create AppStore (1 hour)

Merge all store logic into AppStore:

**From AppState:**
- allTasks
- currentUser
- startup()
- setupPermanentRealtimeSync()
- claimTask()
- deleteTask()

**From AuthenticationStore:**
- isAuthenticated
- login()
- signup()
- logout()
- restoreSession()

**From InboxStore:**
- inboxTasks (computed)
- acknowledgeListing()

**From MyTasksStore:**
- myTasks (computed)

**From MyListingsStore:**
- myListings (computed)
- acknowledgeListing()

**New:**
- selectedTaskFilter (UI state)
- expandedTaskIds (UI state - supports multiple)
- refresh()

### Phase 4: Update Views (3-4 hours)

**Every view changes from:**
```swift
@State private var store: XStore

init(repository: TaskRepositoryClient) {
    _store = State(initialValue: XStore(repository: repository))
}

var body: some View {
    List(store.tasks) { task in ... }
}
```

**To:**
```swift
@Environment(AppStore.self) var appStore

var body: some View {
    List(appStore.myTasks) { task in ... }
}
```

**Files to update (45 views):**
- All Feature views (InboxView, MyTasksView, etc.)
- All Detail views (ListingDetailView, AgentDetailView)
- All List views (AllTasksView, AllListingsView)

### Phase 5: Test (1-2 hours)

- Test auth flow: login, logout, session restoration
- Test data: claim task, create note, acknowledge listing
- Test realtime: new task appears, claim updates, note shows
- Test UI: expansion state persists, filters work
- Test performance: navigation doesn't repeat requests

---

## File Changes Summary

**Delete (13 files):**
```
AppState.swift
AuthenticationStore.swift
InboxStore.swift
MyTasksStore.swift
MyListingsStore.swift
AllTasksStore.swift
AllListingsStore.swift
ListingDetailStore.swift
LogbookStore.swift
TeamViewStore.swift
MarketingTeamStore.swift
AdminTeamStore.swift
AgentDetailStore.swift
```

**Create (1 file):**
```
AppStore.swift (500 lines)
```

**Modify (40+ files):**
```
All Views:
- Remove @State private var store
- Remove init(repository:)
- Add @Environment(AppStore.self) var appStore
- Change store.property → appStore.property

Examples:
- InboxView.swift
- MyTasksView.swift
- AllTasksView.swift
- ListingDetailView.swift
- All other feature screens
```

**Keep (unchanged):**
```
RootView.swift (AppStore injection)
OperationsCenterApp.swift (AppStore creation)
Dependencies (TaskRepositoryClient, etc.)
Models (Activity, Listing, etc.)
Components (Cards, buttons, etc.)
```

---

## Before/After Comparison

### Before
```
OperationsCenterApp
  └─ AppState (unused)
  └─ AppView
      └─ AuthenticationStore
      └─ RootView
          ├─ creates InboxStore → InboxView
          ├─ creates MyTasksStore → MyTasksView
          ├─ creates AllTasksStore → AllTasksView
          ├─ creates ListingDetailStore → ListingDetailView
          └─ ... (10 more stores)

Result: 15 sources of truth
```

### After
```
OperationsCenterApp
  └─ AppStore (single source of truth)
  └─ AppView
      └─ RootView
          ├─ InboxView (reads appStore.inboxTasks)
          ├─ MyTasksView (reads appStore.myTasks)
          ├─ AllTasksView (reads appStore.allTasks)
          ├─ ListingDetailView (reads appStore.activities)
          └─ ... (all views)

Result: 1 source of truth
```

---

## Data Flow Before vs After

### Before (Broken)
```
User claims task
  ↓
InboxStore.claimTask() 
  ↓
  ├─ Network request
  ├─ InboxStore.fetchTasks() (refetch)
  ↓
AppState realtime subscription
  ├─ Receives change
  ├─ Updates AppState.allTasks
  ↓
Two stores out of sync
```

### After (Fixed)
```
User claims task
  ↓
AppStore.claimTask()
  ↓
  ├─ Network request
  └─ (No manual refresh needed)
  ↓
AppStore realtime subscription
  ├─ Receives change
  ├─ Updates AppStore.allTasks
  ↓
All computed properties auto-update
  ├─ appStore.inboxTasks auto-updates
  ├─ appStore.myTasks auto-updates
  ├─ appStore.myListings auto-updates
  ↓
All views seeing same data
```

---

## Testing Checklist

- [ ] AppStore initializes correctly
- [ ] startup() loads data
- [ ] login/logout works
- [ ] Session restoration works
- [ ] currentUser updates propagate
- [ ] Claiming task updates appStore.myTasks
- [ ] Creating note updates appStore
- [ ] Realtime changes appear in UI
- [ ] Navigation preserves expansion state (now in AppStore)
- [ ] Filters work (marketing vs admin)
- [ ] All views read from appStore
- [ ] Preview data works
- [ ] No memory leaks
- [ ] No duplicate network requests

---

## Commit Strategy

**Commit 1:** Delete old stores
```
Delete: AppState, AuthenticationStore, all feature stores
```

**Commit 2:** Create AppStore
```
Create: AppStore.swift with full implementation
```

**Commit 3:** Update views (batch by feature)
```
Update: InboxView + supporting views
Update: MyTasksView + supporting views
Update: AllTasksView + supporting views
... etc
```

**Commit 4:** Cleanup
```
Update: RootView (remove store creation)
Update: OperationsCenterApp (create AppStore)
Update: Dependencies (if needed)
```

---

## Risk Mitigation

**Risk: Break auth flow**
- Mitigation: Test login/logout before moving views
- Checkpoint: Create AppStore, test auth alone

**Risk: Data divergence during transition**
- Mitigation: Keep old stores until all views updated
- Checkpoint: Update views in batches, test each batch

**Risk: Performance regression**
- Mitigation: Profile network requests
- Checkpoint: Ensure no duplicate fetches

---

## Success Criteria

- All 12 audit findings fixed
- Zero warnings from compiler
- All tests pass
- No memory leaks
- Navigation smooth and fast
- New task appears immediately (realtime)
- All views show consistent data

---

## Next Steps

1. Read STATE_AUDIT_FINDINGS.md (understand the problems)
2. Read STATE_MANAGEMENT_AUDIT_COMPREHENSIVE.md (deep dive)
3. Design AppStore structure
4. Start Phase 2: Delete old stores
5. Create AppStore (Phase 3)
6. Update views one feature at a time (Phase 4)
7. Test thoroughly (Phase 5)

---

## Estimated Timeline

- Day 1: Design (30 min) + Phase 2-3 (1.5 hours) = 2 hours
- Day 2: Phase 4 (views) = 3-4 hours
- Day 3: Phase 5 (testing) + fixes = 2-3 hours

**Total: 7-9 hours** (one feature sprint)

---

## Questions?

Key decisions before starting:
1. Should expandedTaskIds be Set or single String? (Set allows multiple)
2. Should filters live in AppStore or views? (AppStore for consistency)
3. Should navigation state be in AppStore? (Yes, for persistence)
4. How to handle preview data? (Initialize with mock in init)

All these are addressed in STATE_MANAGEMENT_AUDIT_COMPREHENSIVE.md.
