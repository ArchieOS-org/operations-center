# STATE MANAGEMENT AUDIT: Operations Center iOS App
**Date:** November 18, 2025  
**Auditor:** Steve Jobs  
**Focus:** Data flow, predictability, thread safety, state duplication  
**Verdict:** ARCHITECTURE HAS CRITICAL FLAWS

---

## EXECUTIVE SUMMARY

Your state management is a **paradox**: brilliant in isolation, broken in aggregate.

**The Good:**
- @Observable pattern implemented correctly on individual stores
- @MainActor prevents thread chaos
- Async/await used properly throughout
- No @StateObject legacy pollution

**The Bad:**
- **Two competing state sources** (AppState + Feature Stores) cause divergence
- **AppState is a zombie** - created but barely used
- **Data flow is murky** - unclear which source of truth wins
- **Refresh operations cause cascading refetches** - inefficient
- **State collisions possible** - same data in multiple stores out of sync

**The Ugly:**
- Views create stores on every navigation (performance leak)
- Authentication state fragmented across stores
- Realtime subscription in AppState doesn't update feature stores
- Preview data manually stuffed into state properties

---

## 1. ARCHITECTURE PROBLEM: TWO COMPETING STATE SOURCES

### The Conflict

You have **two separate hierarchies fighting for truth**:

**Hierarchy 1: AppState (Global)**
```
AppState (created in OperationsCenterApp)
├── allTasks: [Activity]
├── currentUser: Supabase.User?
├── realtimeSubscription (permanent)
└── myTasks, inboxTasks (computed)
```

**Hierarchy 2: Feature Stores (Local)**
```
InboxStore     → tasks: [TaskWithMessages] + listings: [ListingWithDetails]
MyTasksStore   → tasks: [AgentTask]
AllTasksStore  → tasks: [TaskWithMessages] + activities: [ActivityWithDetails]
MyListingsStore → listings: [Listing]
ListingDetail → activities: [Activity]
```

### The Problem

1. **AppState has all tasks. Feature stores have filtered tasks.** If you claim a task:
   - AppState gets realtime update (via subscription) ✓
   - Feature store doesn't know until next fetch ✗
   - UI shows task in Inbox, but missing from AllTasks until refresh
   
2. **currentUser in AppState never reaches feature stores.**
   - AuthenticationStore manages auth separately
   - AppState has its own currentUser
   - Feature stores inject @Dependency(\.authClient) separately
   - Three sources of user identity across the app
   
3. **Computed properties in AppState are useless:**
   ```swift
   var inboxTasks: [Activity] { 
     allTasks.filter { $0.assignedStaffId == nil } 
   }
   ```
   But InboxView never sees this. It uses InboxStore.tasks instead, which has different data (TaskWithMessages, not Activity).

### Where This Breaks

**Scenario 1: User claims a task**
```
User → Claims task in InboxView via InboxStore
    ↓
InboxStore.claimTask() sends request
    ↓
RLS row-level security approves (user owns it now)
    ↓
Two paths fork:
  Path A: AppState realtime subscription catches the change
          → AppState.allTasks updates immediately
  Path B: InboxStore calls fetchTasks() to refresh
          → Makes redundant network call
          → Results might diverge if data changed between requests
```

**Scenario 2: New task appears from Slack webhook**
```
Backend creates task
    ↓
AppState realtime subscription catches it
    → AppState.allTasks has it
    ↓
But user is on MyTasksView, which uses MyTasksStore
MyTasksStore hasn't been notified
→ Task doesn't appear until user navigates away and back
```

---

## 2. USELESS APPASTATE

AppState is created but barely used. Evidence:

**In OperationsCenterApp:**
```swift
let appState = AppState(
    supabase: supabase,
    taskRepository: usePreviewData ? .preview : .live
)
_appState = State(initialValue: appState)
```

**In AppView:**
```swift
@Environment(AppState.self) private var appState
// But appState is NEVER USED inside AppView
```

**In RootView:**
```swift
@Environment(AppState.self) private var appState
// Only used for startup:
.task { 
    guard !CommandLine.arguments.contains("--use-preview-data") else { return }
    await appState.startup()
}
// After startup, never touched again
```

**In ContentView:**
```swift
@Environment(AppState.self) private var appState
// Uses appState.isLoading, appState.errorMessage, appState.allTasks
// But ContentView is NOT IN YOUR NAVIGATION
```

**Result:** AppState startup happens once, then every feature creates its own store. AppState becomes a sunk cost.

---

## 3. FRAGMENTED AUTHENTICATION STATE

Three authentication sources:

**Source 1: AuthenticationStore**
```swift
var isAuthenticated: Bool
var currentUser: Supabase.User?
var error: AuthError?
```

**Source 2: AppState**
```swift
var currentUser: Supabase.User?
```

**Source 3: Dependency Injection**
```swift
@ObservationIgnored @Dependency(\.authClient) private var authClient
// Called everywhere for currentUserId()
```

**What can go wrong:**
- User logs out in AuthenticationStore
- AppState doesn't know yet
- Feature stores using authClient still return old user ID
- Race condition: which user gets the task assignment?

---

## 4. STORE CREATION ON EVERY NAVIGATION

In RootView:
```swift
@ViewBuilder
private func destinationView(for route: Route) -> some View {
    let taskRepo = usePreviewData ? .preview : .live
    
    switch route {
    case .inbox:
        InboxView(store: InboxStore(  // ← NEW STORE CREATED
            taskRepository: taskRepo,
            listingRepository: listingRepo,
            noteRepository: noteRepo,
            realtorRepository: realtorRepo
        ))
    case .myTasks:
        MyTasksView(repository: taskRepo)  // ← NEW STORE CREATED
    }
}
```

**Problem:** Each time user navigates to a screen, a new store is created. The old store is deallocated. Data loss during navigation.

**Example:**
1. User expands a task in InboxView → expandedTaskId = "task-123"
2. User taps a link to AgentDetail
3. User navigates back
4. NEW InboxView created with NEW InboxStore
5. expandedTaskId = nil (lost the expansion state)
6. Network request fires again (duplicate data fetch)

---

## 5. REALTIME SUBSCRIPTION DOESN'T PROPAGATE

AppState has a permanent realtime subscription:
```swift
private func setupPermanentRealtimeSync() async {
    realtimeSubscription = Task { [weak self] in
        guard let self else { return }
        do {
            try await channel.subscribeWithError()
            for await change in channel.postgresChange(AnyAction.self, table: "activities") {
                await self.handleRealtimeChange(change)
            }
        }
    }
}

private func handleRealtimeChange(_ change: AnyAction) async {
    // Refreshes AppState.allTasks
    let taskData = try await taskRepository.fetchActivities()
    self.allTasks = taskData.map(\.task)
}
```

But feature stores don't know about this. They fetch independently:
- InboxStore calls taskRepository.fetchActivities() in fetchTasks()
- MyListingsStore calls taskRepository.fetchActivitiesByStaff()
- AllTasksStore calls taskRepository.fetchActivities()

**Result:** 
- AppState gets realtime updates (good)
- Feature stores don't (bad)
- If user gets a new task, AppState knows immediately, but they won't see it until they refresh

---

## 6. FILTER LOGIC SPREAD ACROSS STORES

Each store reimplements filtering:

**AppState:**
```swift
var inboxTasks: [Activity] {
    allTasks.filter { $0.assignedStaffId == nil }
}

var myTasks: [Activity] {
    guard let userId = currentUser?.id.uuidString else { return [] }
    return allTasks.filter { $0.assignedStaffId == userId }
}
```

**InboxStore:**
```swift
// Filters activities by unacknowledged listing IDs
let filteredActivities = activities.filter { unacknowledgedIds.contains($0.listing.id) }
```

**MyTasksStore:**
```swift
tasks = allAgentTasks.filter { task in
    task.assignedStaffId == currentUserId &&
    (task.status == .claimed || task.status == .inProgress)
}
```

**AllListingsStore:**
```swift
private func updateFilteredListings() {
    if selectedCategory == nil {
        filteredListings = listings
    } else {
        filteredListings = listings.filter { listing in
            listingCategories[listing.id]?.contains(selectedCategory) ?? false
        }
    }
}
```

**Problem:** If filtering logic changes (new requirement: hide archived listings), you update it in 4 places. Someone forgets one. Stores diverge.

---

## 7. RACE CONDITIONS IN BATCH OPERATIONS

**InboxStore example:**
```swift
func fetchTasks() async {
    isLoading = true
    errorMessage = nil

    do {
        let currentUserId = try await authClient.currentUserId()  // ← Async call 1
        
        async let agentTasks = taskRepository.fetchTasks()         // ← Async call 2
        async let activityDetails = taskRepository.fetchActivities() // ← Async call 3
        async let unacknowledgedListingIds = listingRepository.fetchUnacknowledgedListings(currentUserId) // ← Async call 4
        
        tasks = try await agentTasks
        let activities = try await activityDetails
        let unacknowledgedIds = Set(try await unacknowledgedListingIds.map { $0.id })
        
        // What if currentUserId changed between call 1 and call 4?
        // What if listings were deleted between fetches?
```

**Race condition:** If user logs out while fetchTasks() is running:
- currentUserId becomes nil
- But subsequent async let tasks are already in flight
- They complete with old userId data
- Store updates with stale user's data

---

## 8. EXPANSION STATE PATTERN FRAGILITY

Every store has:
```swift
var expandedTaskId: String?
```

But this pattern is fragile:

**InboxStore:**
```swift
func toggleExpansion(for taskId: String) {
    if expandedTaskId == taskId {
        expandedTaskId = nil
    } else {
        expandedTaskId = taskId
    }
}
```

**Problem 1:** Only one task can be expanded at a time across entire Inbox. If you have listings with nested activities, you can't expand both.

**Problem 2:** If user taps back button while a task is expanded, the expansion state is lost (store recreated).

**Problem 3:** Navigation doesn't preserve this UI state:
```swift
case .listing(let id):
    ListingDetailView(listingId: id, ...)  // ← NEW STORE CREATED
```

Expansion state in ListingDetailStore gets reset.

---

## 9. PREVIEW DATA CORRUPTION

In OperationsCenterApp:
```swift
if usePreviewData {
    appState.allTasks = [.mock1, .mock2, .mock3]  // ← Directly mutating state
}
```

In ContentView preview:
```swift
let appState = AppState(supabase: supabase, taskRepository: .preview)
appState.allTasks = [Activity.mock1, Activity.mock2, Activity.mock3]  // ← Direct mutation
```

**Problem:** You're mutating observable state during initialization. This bypasses proper initialization patterns and makes it unclear if the mock data is real or just preview junk.

---

## 10. UNIDIRECTIONAL DATA FLOW IS BROKEN

**Goal:** Unidirectional flow (user action → state change → UI update)

**Reality:**
```
User taps "Claim" → 
  InboxView.claimTask() → 
    InboxStore.claimTask() → 
      taskRepository.claimTask() (network request) → 
        InboxStore.fetchTasks() (refresh) → 
          taskRepository.fetchActivities() → 
            InboxStore.tasks updated → 
              UI refreshes

Meanwhile:
AppState realtime subscription → AppState.allTasks updated → UI ignores it
```

**The problem:** Data is flowing in multiple directions. AppState can update independently of InboxStore, causing them to diverge.

---

## 11. NO INVALIDATION STRATEGY

When you perform an action (claim task, create note), stores refresh:

**MyTasksStore:**
```swift
func claimTask(_ task: AgentTask) async {
    _ = try await repository.claimTask(...)
    await fetchMyTasks()  // ← Refresh entire store
}
```

**InboxStore:**
```swift
func addNote(to listingId: String, content: String) async {
    _ = try await noteRepository.createNote(...)
    await fetchTasks()  // ← Refresh entire Inbox
}
```

**Problem:** You don't invalidate caches, you refetch everything. This works but is:
1. Inefficient (N+1 requests)
2. Racy (if data changes again during fetch)
3. Doesn't work across stores (MyListingsStore doesn't know its data changed)

---

## 12. COMPUTED PROPERTIES BASED ON STALE STATE

**AllTasksStore:**
```swift
var filteredActivities: [ActivityWithDetails] {
    switch teamFilter {
    case .all:
        return activities  // ← Which activities? From where?
    case .marketing:
        return activities.filter { $0.task.visibilityGroup == .marketing || ... }
    }
}
```

What if activities are out of sync with filteredActivities because a fetch happened but didn't complete? Computed property returns stale data.

---

## RECOMMENDATIONS

### 1. UNIFY STATE HIERARCHY

**Delete AppState.** It's competing with feature stores.

Instead, create a single **AppStore** that owns all state:
```swift
@Observable @MainActor
final class AppStore {
    // Authentication
    var currentUser: Supabase.User?
    var isAuthenticated: Bool = false
    
    // All tasks (source of truth)
    var allTasks: [Activity] = []
    
    // User selections (UI state)
    var selectedTeamFilter: TeamFilter = .all
    var expandedTaskId: String?
    
    // Loading/error
    var isLoading = false
    var errorMessage: String?
    
    // Setup realtime once, here
    private func setupRealtimeSync() { ... }
}
```

Feature views read what they need:
```swift
struct InboxView: View {
    @Environment(AppStore.self) var appStore
    
    var body: some View {
        // Show unacknowledged listings from appStore
        List(appStore.unacknowledgedListings) { listing in ... }
    }
}
```

### 2. COMPUTED PROPERTIES ONLY, NO FILTERING IN STORES

```swift
extension AppStore {
    var inboxTasks: [Activity] {
        allTasks.filter { $0.assignedStaffId == nil }
    }
    
    var myTasks: [Activity] {
        guard let userId = currentUser?.id.uuidString else { return [] }
        return allTasks.filter { $0.assignedStaffId == userId }
    }
}
```

One place to change filtering logic.

### 3. ELIMINATE FEATURE STORES

Views don't need stores. They read from AppStore:

```swift
struct MyTasksView: View {
    @Environment(AppStore.self) var appStore
    
    var body: some View {
        List(appStore.myTasks) { task in ... }
    }
}
```

Much simpler. No accidental state duplication.

### 4. NAVIGATION PRESERVES UI STATE

Store UI state (expansion, selection) in navigation instead:
```swift
NavigationStack(path: $path) {
    List {
        ForEach(appStore.myTasks) { task in
            NavigationLink(value: task.id) {
                taskRow(task)
            }
        }
    }
    .navigationDestination(for: String.self) { taskId in
        TaskDetailView(taskId: taskId)
    }
}
```

No expansion state to lose when you navigate.

### 5. REALTIME UPDATES INVALIDATE CORRECTLY

```swift
private func setupRealtimeSync() async {
    let channel = supabase.realtimeV2.channel("all_tasks")
    
    Task {
        for await change in channel.postgresChange(...) {
            // Instead of refetching, just update locally:
            if let index = allTasks.firstIndex(where: { $0.id == change.record.id }) {
                allTasks[index] = change.record
            }
        }
    }
}
```

Realtime updates apply immediately, not after a full refresh.

### 6. CLEAR INVALIDATION POINTS

After mutations, invalidate cache explicitly:
```swift
func claimTask(_ taskId: String) async {
    try await repository.claimTask(taskId, currentUser!.id.uuidString)
    // Realtime will update automatically
    // No manual refresh needed
}
```

---

## CONCLUSION

Your state management architecture is trying to be three different patterns at once:
1. Global app state (AppState)
2. Feature-scoped stores (InboxStore, MyTasksStore)
3. Dependency injection (authClient)

Pick one. Use @Observable with a single AppStore. Read what you need. Stop fighting your own architecture.

**The simplicity you're missing:** One source of truth. All views read from it. Realtime updates propagate automatically. No duplication. No divergence. No refresh loops.

Delete the complexity. Ship the simplicity.
