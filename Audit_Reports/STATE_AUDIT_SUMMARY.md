# STATE MANAGEMENT AUDIT SUMMARY
**Audit Date:** November 18, 2025  
**Status:** CRITICAL ISSUES FOUND

## Critical Findings

### 1. Two Competing State Hierarchies
**Severity:** CRITICAL  
**Files:** AppState.swift, *Store.swift (14 files)

Your app has AppState (global) AND 14 feature stores (local), both trying to own task data. This causes:
- Data divergence when AppState receives realtime updates that feature stores don't
- Redundant network requests
- State collisions (same task represented differently in different stores)

**Example:** User claims task in Inbox → AppState gets realtime update → MyTasksView doesn't see it until refresh

### 2. AppState is Effectively Unused
**Severity:** HIGH  
**Files:** OperationsCenterApp.swift, RootView.swift, AppView.swift

AppState is created, started, but then abandoned. Every feature creates its own store instead:
```
RootView: Creates InboxStore, MyTasksStore, AllTasksStore...
Result: AppState startup() runs once, then ignored
```

**Recommendation:** Delete AppState. Use a single unified store instead.

### 3. Fragmented Authentication State
**Severity:** HIGH  
**Files:** AuthenticationStore.swift, AppState.swift, authClient.swift

User identity split across three sources:
1. AuthenticationStore.currentUser
2. AppState.currentUser  
3. @Dependency(\.authClient)

If user logs out, which one gets notified first? Race condition.

### 4. Stores Created on Every Navigation
**Severity:** MEDIUM  
**Files:** RootView.swift

```swift
case .inbox:
    InboxView(store: InboxStore(...))  // ← NEW STORE CREATED EACH TIME
```

Result:
- Expansion state lost on navigation back
- Network requests repeat
- Performance leak

### 5. Realtime Subscription Doesn't Propagate
**Severity:** HIGH  
**Files:** AppState.swift

AppState has permanent realtime subscription that updates AppState.allTasks. But feature stores fetch independently:
- InboxStore.fetchTasks() (separate call)
- MyListingsStore.fetchMyListings() (separate call)  
- AllTasksStore.fetchAllTasks() (separate call)

Result: AppState knows about new tasks immediately, but views don't see them until they refresh.

### 6. Filter Logic Duplicated Across Stores
**Severity:** MEDIUM  
**Files:** AppState, InboxStore, MyTasksStore, AllListingsStore, AllTasksStore

Same filtering logic implemented 5 different ways:
- AppState.inboxTasks
- InboxStore.listings (filtered by acknowledgment)
- MyTasksStore.tasks (filtered by status)
- AllListingsStore.filteredListings (filtered by category)
- AllTasksStore.filteredTasks (filtered by team)

If requirements change, need to update 5+ places.

### 7. Race Conditions in Batch Operations
**Severity:** MEDIUM  
**File:** InboxStore.swift

```swift
func fetchTasks() async {
    let currentUserId = try await authClient.currentUserId()  // Call 1
    async let tasks = repository.fetchTasks()                 // Call 2
    async let activities = repository.fetchActivities()       // Call 3
    let unacknowledgedIds = try await ...                     // Call 4
    
    // What if user logs out between call 1 and call 4?
```

If user logs out while fetch is in flight, store updates with stale data.

### 8. Expansion State Lost on Navigation
**Severity:** MEDIUM  
**Files:** All views with expandedTaskId

Each store has `var expandedTaskId: String?`. When user navigates away and back, store is recreated. Expansion state = nil. Bad UX.

### 9. Preview Data Directly Mutates State
**Severity:** LOW  
**Files:** OperationsCenterApp.swift, ContentView.swift

```swift
appState.allTasks = [.mock1, .mock2, .mock3]
```

Direct mutation during init. Unclear if data is real or preview junk. Defeats testing.

### 10. No Invalidation Strategy
**Severity:** MEDIUM  
**Files:** All stores

After every action (claim, create note), stores refresh everything:
```swift
_ = try await repository.claimTask(...)
await fetchMyTasks()  // ← Refetch entire store
```

Inefficient. Should invalidate caches, not refetch.

---

## Root Cause

**Your architecture is trying to be three patterns at once:**

1. Global app state (AppState)
2. Feature-scoped stores (InboxStore, etc.)
3. Dependency injection (authClient)

This creates confusion about which is the source of truth.

---

## The Fix (High Level)

**Delete this:**
- AppState (12KB gone)
- All feature stores (14 stores gone)
- AuthenticationStore (move auth to app store)

**Replace with this:**
- Single `AppStore` that owns all state
- Views read computed properties from AppStore
- No duplication
- One source of truth

**Result:**
- AppStore.allTasks ← source of truth
- AppStore.myTasks ← computed from allTasks
- AppStore.inboxTasks ← computed from allTasks
- Realtime updates to allTasks propagate automatically
- No refresh loops
- No data divergence

---

## Files Affected

**Delete (12 files):**
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

**Create (1 file):**
- AppStore.swift (unified, single source of truth)

**Modify (40+ files):**
- All views change from `@State private var store: XStore` to `@Environment(AppStore.self) var appStore`

---

## Estimated Effort

**Refactor:** 3-4 hours  
**Testing:** 2 hours  
**Review:** 1 hour  
**Total:** 6-7 hours

**Worth it:** YES. Current architecture has bugs waiting to happen.

---

## See Also

Full analysis: STATE_MANAGEMENT_AUDIT_COMPREHENSIVE.md
