# State Management Audit: Detailed Findings
**November 18, 2025**

---

## Finding 1: Two Competing State Sources

### Problem
AppState owns "allTasks" and listens to realtime updates. But every feature screen creates its own store that owns different task collections.

### Evidence

**AppState.swift (lines 19-46):**
```swift
@Observable
@MainActor
final class AppState {
    var allTasks: [Activity] = []
    var currentUser: Supabase.User?
    
    var inboxTasks: [Activity] {
        allTasks.filter { $0.assignedStaffId == nil }
    }
    
    var myTasks: [Activity] {
        guard let userId = currentUser?.id.uuidString else { return [] }
        return allTasks.filter { $0.assignedStaffId == userId }
    }
}
```

But then InboxStore has its own tasks collection:
```swift
@Observable @MainActor
final class InboxStore {
    var tasks: [TaskWithMessages] = []
    var listings: [ListingWithDetails] = []
}
```

And MyTasksStore:
```swift
@Observable @MainActor
final class MyTasksStore {
    var tasks: [AgentTask] = []
}
```

### Why This Breaks

**Scenario: User claims a task in Inbox**

1. User taps "Claim" on a task in InboxView
2. InboxStore.claimTask() calls repository.claimTask() → network request
3. RLS policy approves (user ID matches)
4. Supabase publishes realtime event
5. Two paths:
   - **Path A (AppState):** Realtime subscription → AppState.allTasks updated immediately
   - **Path B (InboxStore):** Calls fetchTasks() → refreshes from network

If these complete at different times, AppState.allTasks and InboxStore.tasks are temporarily out of sync.

**Worse:** If user navigates away from Inbox before Path B completes, they never see InboxStore.tasks update. Come back later, new store is created, and it fetches again.

---

## Finding 2: AppState Startup Runs But Stores Unused

### Problem
AppState.startup() is called in RootView, but AppState is never read afterwards. Every feature creates its own store.

### Evidence

**OperationsCenterApp.swift:**
```swift
let appState = AppState(supabase: supabase, taskRepository: .live)
_appState = State(initialValue: appState)
```

**RootView.swift (lines 10-12):**
```swift
@Environment(AppState.self) private var appState
@State private var path: [Route] = []

var body: some View {
    .task {
        guard !CommandLine.arguments.contains("--use-preview-data") else { return }
        await appState.startup()  // ← Called once
    }
}
```

Then in destinationView (lines 76-82):
```swift
switch route {
case .inbox:
    InboxView(store: InboxStore(
        taskRepository: taskRepo,
        listingRepository: listingRepo,
        noteRepository: noteRepo,
        realtorRepository: realtorRepo
    ))  // ← Creates NEW store, ignores AppState
}
```

**Result:** AppState.startup() runs once, but the data it fetches (AppState.allTasks) is never used.

---

## Finding 3: Three Authentication Sources

### Problem
User identity is owned by three different objects with no synchronization.

### Evidence

**AuthenticationStore.swift:**
```swift
@MainActor
@Observable
final class AuthenticationStore {
    var isAuthenticated = false
    var currentUser: Supabase.User?
}
```

**AppState.swift:**
```swift
@Observable
@MainActor
final class AppState {
    var currentUser: Supabase.User?
}
```

**Feature stores use dependency injection:**
```swift
@ObservationIgnored @Dependency(\.authClient) private var authClient

let userId = try await authClient.currentUserId()
```

### Why This Breaks

**Race condition during logout:**

1. User taps Logout in Settings
2. AuthenticationStore.logout() → tries to sign out
3. At same time, InboxStore.fetchTasks() is running
4. fetchTasks() gets currentUserId from authClient → which value? Old or new?
5. If old value: task gets assigned to wrong user
6. If new value (nil): crash

No synchronization between logout and in-flight requests.

---

## Finding 4: Stores Recreated on Every Navigation

### Problem
Each navigation creates a new store. UI state (expansion, selection) is lost.

### Evidence

**RootView.swift (destinationView):**
```swift
switch route {
case .inbox:
    InboxView(store: InboxStore(...))  // NEW
case .myTasks:
    MyTasksView(repository: taskRepo)  // NEW
case .listing(let id):
    ListingDetailView(...)  // NEW STORE
}
```

Every time user navigates to a route, a fresh store is created.

### Why This Breaks

**Expansion state loss:**

1. User is in Inbox, expands a task
2. InboxStore.expandedTaskId = "task-123"
3. User taps to see task detail
4. User taps back to Inbox
5. NEW InboxStore created
6. expandedTaskId = nil (not in stored navigation)
7. Task is not expanded

**Network requests repeat:**

1. User goes to Inbox
2. InboxStore.fetchTasks() fires
3. User navigates to detail
4. User comes back
5. NEW InboxStore, fetchTasks() fires again (duplicate request)

---

## Finding 5: Realtime Doesn't Update Feature Stores

### Problem
AppState listens to realtime changes. Feature stores don't. They're out of sync.

### Evidence

**AppState.swift (lines 125-163):**
```swift
private func setupPermanentRealtimeSync() async {
    let channel = supabase.realtimeV2.channel("all_tasks")
    
    realtimeSubscription = Task { [weak self] in
        guard let self else { return }
        do {
            try await channel.subscribeWithError()
            for await change in channel.postgresChange(AnyAction.self, table: "activities") {
                await self.handleRealtimeChange(change)
            }
        } catch { ... }
    }
}

private func handleRealtimeChange(_ change: AnyAction) async {
    let taskData = try await taskRepository.fetchActivities()
    self.allTasks = taskData.map(\.task)
}
```

AppState gets realtime updates. But InboxStore doesn't have a subscription:

```swift
@Observable @MainActor
final class InboxStore {
    // NO realtime subscription
    // Only fetches on demand
}
```

### Why This Breaks

**New task from Slack webhook:**

1. Backend webhook creates new task
2. Supabase publishes realtime event
3. AppState.setupPermanentRealtimeSync() receives it
4. AppState.allTasks updated immediately
5. But user is viewing MyTasksView
6. MyTasksStore has no subscription, doesn't know about new task
7. User has to navigate away and back to see it

---

## Finding 6: Filter Logic Duplicated 5 Ways

### Problem
Same business logic (which tasks belong in which view) implemented separately in each store.

### Evidence

**AppState.swift:**
```swift
var inboxTasks: [Activity] {
    allTasks.filter { $0.assignedStaffId == nil }
}

var myTasks: [Activity] {
    guard let userId = currentUser?.id.uuidString else { return [] }
    return allTasks.filter { $0.assignedStaffId == userId }
}
```

**MyTasksStore.swift:**
```swift
tasks = allAgentTasks.filter { task in
    task.assignedStaffId == currentUserId &&
    (task.status == .claimed || task.status == .inProgress)
}
```

**InboxStore.swift:**
```swift
let filteredActivities = activities.filter { unacknowledgedIds.contains($0.listing.id) }
```

**AllTasksStore.swift:**
```swift
private func updateFilteredTasks() {
    switch teamFilter {
    case .all:
        filteredTasks = tasks
    case .marketing:
        filteredTasks = tasks.filter { $0.task.taskCategory == .marketing }
    case .admin:
        filteredTasks = tasks.filter { $0.task.taskCategory == .admin }
    }
}
```

**MyListingsStore.swift:**
```swift
private func updateFilteredListings() {
    guard let selectedCategory else {
        filteredListings = listings
        return
    }
    filteredListings = listings.filter { listing in
        listingCategories[listing.id]?.contains(selectedCategory) ?? false
    }
}
```

### Why This Breaks

**Requirement change: Hide archived listings**

You need to add `.filter { !$0.isArchived }` to each store. 5 places to change. Someone forgets InboxStore. Now Inbox shows archived, but MyTasks doesn't. Data inconsistency.

---

## Finding 7: Race Conditions in Batch Fetches

### Problem
InboxStore fetches from multiple sources. If auth changes mid-fetch, data diverges.

### Evidence

**InboxStore.swift (lines 54-70):**
```swift
func fetchTasks() async {
    isLoading = true
    
    do {
        let currentUserId = try await authClient.currentUserId()  // ← Async call A
        
        async let agentTasks = taskRepository.fetchTasks()         // ← Async call B
        async let activityDetails = taskRepository.fetchActivities()  // ← Async C
        async let unacknowledgedListingIds = listingRepository.fetchUnacknowledgedListings(currentUserId)  // ← Async D
        
        tasks = try await agentTasks
        let activities = try await activityDetails
        let unacknowledgedIds = Set(try await unacknowledgedListingIds.map { $0.id })
```

**Problem sequence:**

1. Call A: currentUserId = "user-123"
2. User logs out in another part of app
3. Call D: fetchUnacknowledgedListings gets called with "user-123" (stale)
4. Realtime event fires (user-123 just logged out)
5. AuthenticationStore updated
6. But InboxStore is already mid-fetch
7. Results complete: tasks assigned to logged-out user

---

## Finding 8: Expansion State Lost on Navigation

### Problem
UI state (which card is expanded) stored in local store that gets recreated.

### Evidence

**InboxStore.swift:**
```swift
var expandedTaskId: String?

func toggleExpansion(for taskId: String) {
    expandedTaskId = expandedTaskId == taskId ? nil : taskId
}
```

**InboxView.swift:**
```swift
let store: InboxStore

.overlay(alignment: .bottom) {
    if let expandedId = store.expandedTaskId {  // ← Depends on store persistence
        DSContextMenu(actions: ...)
    }
}
```

But when user navigates away and back, RootView creates a new InboxStore. expandedTaskId = nil.

---

## Finding 9: Preview Data Directly Mutates State

### Problem
Mock data stuffed into state during init. Unclear if real or test.

### Evidence

**OperationsCenterApp.swift (lines 31-33):**
```swift
if usePreviewData {
    appState.allTasks = [.mock1, .mock2, .mock3]  // ← Direct mutation
}
```

**ContentView.swift (line 179):**
```swift
appState.allTasks = [Activity.mock1, Activity.mock2, Activity.mock3]
```

This bypasses initialization and makes state mutation hard to trace.

---

## Finding 10: No Cache Invalidation Strategy

### Problem
Actions cause full refetches instead of targeted invalidation.

### Evidence

**MyTasksStore.swift:**
```swift
func claimTask(_ task: AgentTask) async {
    do {
        _ = try await repository.claimTask(task.id, await authClient.currentUserId())
        await fetchMyTasks()  // ← Refetch ENTIRE store
    } catch { ... }
}
```

**InboxStore.swift:**
```swift
func addNote(to listingId: String, content: String) async {
    do {
        _ = try await noteRepository.createNote(listingId, content)
        await fetchTasks()  // ← Refetch ENTIRE Inbox
    } catch { ... }
}
```

### Why This Breaks

After you claim a task, you refetch all tasks. But:
1. Other store (MyListingsStore) doesn't know to invalidate
2. AppState knows (via realtime) but feature stores don't
3. N+1 requests: claim request + refetch request

---

## Finding 11: Computed Properties Can Return Stale Data

### Problem
Computed properties depend on state that might be updating.

### Evidence

**AllTasksStore.swift (lines 167-177):**
```swift
var filteredActivities: [ActivityWithDetails] {
    switch teamFilter {
    case .all:
        return activities  // ← What if activities is updating?
    case .marketing:
        return activities.filter { $0.task.visibilityGroup == .marketing || $0.task.visibilityGroup == .both }
    case .admin:
        return activities.filter { $0.task.visibilityGroup == .agent || $0.task.visibilityGroup == .both }
    }
}
```

If fetchAllTasks() is running and updating activities, filteredActivities might:
- Return half-updated data
- Skip items that were just fetched
- Include deleted items not yet removed

---

## Finding 12: Refresh Cascades Across Stores

### Problem
One store's refresh doesn't trigger other stores to refresh.

### Evidence

**Scenario:**

1. User claims task in InboxView → InboxStore.claimTask()
2. InboxStore calls fetchTasks() to refresh
3. Task moves out of Inbox into MyTasks
4. But MyTasksView is cached (user navigated away)
5. MyTasksView still shows old data
6. Come back to MyTasks → new store created → fetches again (duplicate)

No way to say "invalidate all task-related caches."

---

## Summary Table

| Issue | Severity | Impact | Files |
|-------|----------|--------|-------|
| Two competing states | CRITICAL | Data divergence | AppState + 14 stores |
| AppState unused | HIGH | Wasted code | 4 files |
| Auth fragmented | HIGH | Race conditions | 3 files |
| Stores recreated | MEDIUM | UX regression | RootView |
| Realtime doesn't propagate | HIGH | Late updates | AppState |
| Filters duplicated | MEDIUM | Maintenance hell | 5 stores |
| Race conditions | MEDIUM | Data corruption | InboxStore |
| Expansion lost | MEDIUM | UX regression | All stores |
| Preview data mutates | LOW | Testing issues | 2 files |
| No invalidation | MEDIUM | N+1 requests | All stores |
| Stale computed props | MEDIUM | Inconsistency | AllTasksStore |
| Refresh cascades | MEDIUM | Cache miss | All stores |

