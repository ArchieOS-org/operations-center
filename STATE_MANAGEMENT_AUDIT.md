# State Management Audit: Claimed vs Unclaimed Model

**Investigation Date:** 2025-11-16  
**Branch:** nsd97/audit-quality-gaps  
**Scope:** Task management, listing acknowledgment, logbook integration  

---

## EXECUTIVE SUMMARY

The codebase implements **partial claim/unclaim logic** but is **MISSING critical acknowledgment state management** for listings. Tasks have proper claim mechanics, but listing acknowledgment (a core spec requirement) is completely absent from the database layer.

**Critical Gap:** Per spec, "All staff must acknowledge" listings before they move out of Inbox. This per-user state is not implemented.

---

## 1. CLAIMED TASK MECHANICS ✓ (PARTIAL)

### Implemented: Task Claim/Unclaim

**Repository:** `TaskRepositoryClient.swift` (lines 23-27, 178-195)

```swift
claimTask: { taskId, staffId in
    let now = Date()
    let response: AgentTask = try await supabase
        .from("agent_tasks")
        .update([
            "assigned_staff_id": staffId,
            "claimed_at": now.ISO8601Format(),
            "status": AgentTask.TaskStatus.claimed.rawValue
        ])
        .eq("task_id", value: taskId)
        .single()
        .execute()
        .value
    return response
}

claimActivity: { taskId, staffId in
    let now = Date()
    let response: Activity = try await supabase
        .from("activities")
        .update([
            "assigned_staff_id": staffId,
            "claimed_at": now.ISO8601Format(),
            "status": Activity.TaskStatus.claimed.rawValue
        ])
        .eq("task_id", value: taskId)
        .single()
        .execute()
        .value
    return response
}
```

**Database Schema:** Supports claim with:
- `claimed_at` TIMESTAMPTZ (tracks when claimed)
- `assigned_staff_id` TEXT (tracks who claimed)
- `status` TEXT ENUM (OPEN → CLAIMED → IN_PROGRESS → DONE)

**Status Values:** `OPEN`, `CLAIMED`, `IN_PROGRESS`, `DONE`, `FAILED`, `CANCELLED`

---

## 2. UNCLAIM/REASSIGN MECHANICS ✗ (NOT IMPLEMENTED)

### Missing: Unclaim Operation

**Problem:** No API to unclaim tasks. Once a task is claimed, there's no way to:
- Unclaim a task back to OPEN
- Reassign to a different staff member
- Reset claim status

**Current State:** 
- Tasks can only move forward: OPEN → CLAIMED → IN_PROGRESS → DONE
- No backward movement or reassignment

**Spec Requirement (Line 87):**
> "Tasks... Can be assigned to multiple users (stacked initials)"

**Status:** NOT IMPLEMENTED. No multi-assign logic exists.

---

## 3. LISTING ACKNOWLEDGMENT ✗ (COMPLETELY MISSING)

### Critical Gap: Per-User Acknowledgment State

**Spec Requirements (Lines 35, 100-104, 147-150):**
- "Requires acknowledgment from all staff before appearing in their views"
- "Per-user state: Listing only moves out of YOUR Inbox after YOU acknowledge"
- "Once acknowledged → Appears in your All Listings/Agent Screen"

**Current Implementation:** ZERO

### Database Analysis

**Listings Table Schema (migration 003, 009, 011):**
```sql
listing_id TEXT PRIMARY KEY
address_string TEXT NOT NULL
status TEXT (new, in_progress, completed)
assignee TEXT
agent_id TEXT
realtor_id TEXT (foreign key)
due_date TIMESTAMPTZ
progress NUMERIC
type TEXT
notes TEXT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
completed_at TIMESTAMPTZ
deleted_at TIMESTAMPTZ
```

**Missing:**
- NO `acknowledged_at` column
- NO `acknowledged_by` column
- NO per-user acknowledgment tracking table
- NO acknowledgment state at all

### Swift Layer Issues

**InboxStore.swift (Lines 63-89):**
```swift
// Group activities by listing
let groupedByListing = Dictionary(grouping: activities) { $0.listing.id }

// Build ListingWithDetails for each listing
var listingDetails: [ListingWithDetails] = []
for (listingId, activityGroup) in groupedByListing {
    guard let firstActivity = activityGroup.first else { continue }
    let listing = firstActivity.listing
    // ... create ListingWithDetails
}

listings = listingDetails
```

**Problem:** This shows ALL listings with activities, with NO filtering for per-user acknowledgment.

### InboxView Implementation (Lines 140-163)

```swift
DSContextAction(
    title: "Acknowledge",
    systemImage: "checkmark.circle",
    action: {
        // Mark all activities as acknowledged/claimed
        for activity in listingWithDetails.activities {
            Task { await store.claimActivity(activity) }
        }
    }
),
```

**What's Wrong:**
1. "Acknowledge" button claims ALL activities in the listing
2. This is NOT acknowledgment - it's claiming work
3. No per-user state is recorded
4. The action SHOULD record that THIS USER acknowledged the listing
5. There's no ListingRepositoryClient method for acknowledgment

**Expected Behavior:**
```swift
// Should call something like:
acknowledgeListing(listingId: String, staffId: String) -> Listing
// And record: this user has now seen/acknowledged this listing
```

---

## 4. LISTING STATE FILTERING ISSUES

### AllListingsStore.swift (Lines 46-58)

```swift
func fetchAllListings() async {
    isLoading = true
    errorMessage = nil

    do {
        listings = try await repository.fetchListings()
        Logger.database.info("Fetched \(self.listings.count) listings")
    } catch { ... }
    
    isLoading = false
}
```

**Per Spec (Line 312):** 
> "All Listings across system (acknowledged and unacknowledged)"

**Current Reality:** Returns ALL listings, doesn't distinguish acknowledged/unacknowledged.

### MyListingsStore.swift (Lines 51-76)

```swift
func fetchMyListings() async {
    // Get activities claimed by this realtor
    let userListingTasks = try await taskRepository.fetchActivitiesByRealtor(authClient.currentUserId())
    
    // Extract unique listing IDs
    let listingIds = Set(userListingTasks.map { $0.task.listingId })
    
    // Fetch all listings
    let allListings = try await listingRepository.fetchListings()
    
    // Filter to only listings where user has claimed activities
    listings = allListings.filter { listing in
        listingIds.contains(listing.id)
    }
}
```

**Per Spec (Line 202):**
> "Listings where user has claimed at least one Activity"

**Issue:** Line 57 fetches by realtorId (not staffId), which is WRONG. Should be:
- Filter activities where `assignedStaffId == currentUserId()`
- Not `realtorId == currentUserId()`

**Bug:** The function name `fetchActivitiesByRealtor` is being called with a staff ID, which is semantically incorrect.

---

## 5. LOGBOOK INTEGRATION ✓ (PARTIAL)

### Implemented: Logbook Display

**LogbookStore.swift:**
```swift
func fetchCompletedItems() async {
    async let listingsFetch = listingRepository.fetchCompletedListings()
    async let tasksFetch = taskRepository.fetchCompletedTasks()
    
    let (listings, tasks) = try await (listingsFetch, tasksFetch)
    
    completedListings = listings
    completedTasks = tasks
}
```

**Database Queries:**
- Tasks: `status == "done"`
- Listings: `completed_at IS NOT NULL`

### Missing: Automatic Logbook Movement

**Per Spec (Lines 36, 86):**
- "When ALL Activities are complete → entire Listing → Logbook"
- "When Task completed → → Logbook"

**Current State:** 
- Logbook DISPLAYS completed items
- NO backend logic to automatically mark listings/tasks as done
- NO computation of "all activities complete" status
- Manual/external system must set `completed_at` and `status`

---

## 6. ACTIVITY COMPLETION MECHANICS ✗

### Missing: Activity Completion Flow

**Spec Requirements (Lines 41-62, 61):**
- "When completed: move to bottom of Activity list, show as crossed out"
- "Stay in Listing even after completion (unlike Tasks which go to Logbook)"

**Current State:**
- Activity has `completedAt` field
- Activity has `status` field that can be DONE
- NO UI logic to:
  - Show completed activities at bottom
  - Cross them out
  - Filter/sort by completion

**ActivityCard.swift (from git status):** Recently modified but shows no completion UI.

---

## 7. TASK REASSIGNMENT/UNCLAIM ✗

### Missing: Multi-Assign Logic

**Spec (Line 116):**
> "Can be assigned to multiple users (stacked initials)"

**Current Implementation:**
- AgentTask has single `assignedStaffId: String?`
- No array of assignees
- No multi-assign UI
- No stacked initials component

**Code Pattern:** All task claims use single-value assignment:
```swift
"assigned_staff_id": staffId  // Single value, not array
```

---

## 8. REPOSITORY PROTOCOL GAPS

### TaskRepository Protocol (Lines 13-31)

```swift
public protocol TaskRepository: Sendable {
    func fetchTasks() async throws -> [TaskWithMessages]
    func fetchActivities() async throws -> [ActivityWithDetails]
    func claimTask(taskId: String, staffId: String) async throws -> AgentTask
    func claimActivity(taskId: String, staffId: String) async throws -> Activity
    func deleteTask(taskId: String, deletedBy: String) async throws
    func deleteActivity(taskId: String, deletedBy: String) async throws
}
```

**Missing Methods:**
1. `unclaimTask` / `reassignTask`
2. `completeTask` / `completeActivity`
3. `acknowledgeListingForUser`
4. `fetchListingsRequiringAcknowledgment`
5. `getListingAcknowledgmentStatus`

### ListingRepositoryClient

**Available Methods:**
- `fetchListings()`
- `fetchListing(listingId)`
- `fetchListingsByRealtor(realtorId)`
- `fetchCompletedListings()`
- `deleteListing(listingId, deletedBy)`

**Missing Methods:**
- `acknowledgeListingForUser(listingId, staffId)`
- `hasUserAcknowledged(listingId, staffId)`
- `getUnacknowledgedListings(staffId)`

---

## 9. STORE-LEVEL STATE MANAGEMENT

### InboxStore (State Tracking)

```swift
var tasks: [TaskWithMessages] = []
var listings: [ListingWithDetails] = []
var expandedTaskId: String?
var isLoading = false
var errorMessage: String?
```

**Analysis:**
- Tracks inbox items (unclaimed work)
- Tracks expansion state (UI)
- NO tracking of which listings user has acknowledged
- NO per-user acknowledgment filtering

### MyListingsStore (Claimed Work)

```swift
var listings: [Listing] = []
var expandedListingId: String?
var errorMessage: String?
var isLoading = false
```

**Analysis:**
- Shows listings where user claimed activities
- BUG: Uses `fetchActivitiesByRealtor()` with `currentUserId()` (realtorId vs staffId confusion)
- Doesn't filter by acknowledgment status

### AllListingsStore

```swift
var listings: [Listing] = []
var errorMessage: String?
var isLoading = false
```

**Per Spec:** Should distinguish acknowledged vs unacknowledged.

---

## 10. MODELS & DATA STRUCTURES

### Activity Model (Complete)

```swift
public struct Activity: Identifiable, Codable, Sendable {
    public let id: String
    public let listingId: String
    public let status: TaskStatus  // OPEN, CLAIMED, IN_PROGRESS, DONE, ...
    public var assignedStaffId: String?
    public var claimedAt: Date?
    public let completedAt: Date?
    // ... other fields
}
```

**Status Values:** `OPEN`, `CLAIMED`, `IN_PROGRESS`, `DONE`, `FAILED`, `CANCELLED`

✓ Supports claim/unclaim state  
✓ Supports completion tracking  
✗ No per-user acknowledgment  

### Listing Model (Incomplete)

```swift
public struct Listing: Identifiable, Codable, Sendable {
    public let id: String
    public let addressString: String
    public let status: String  // "new", "in_progress", "completed"
    public let assignee: String?
    public let realtorId: String?
    public let dueDate: Date?
    public let completedAt: Date?
    public let deletedAt: Date?
}
```

✗ No acknowledgment tracking fields  
✗ `assignee` and `realtorId` both exist (confusing)  
✗ Status is string, not enum  

### ListingWithDetails (Incomplete)

```swift
public struct ListingWithDetails: Sendable, Identifiable {
    public let listing: Listing
    public let realtor: Realtor?
    public let activities: [Activity]
    public let notes: [ListingNote]
    public let hasNotesError: Bool
    public let hasMissingRealtor: Bool
}
```

✗ No acknowledgment status per user  
✗ No field for "user has acknowledged this"  

---

## SUMMARY TABLE: State Management Coverage

| Feature | Spec | Implemented | Quality |
|---------|------|-------------|---------|
| **Claim Tasks** | ✓ Line 96-98 | ✓ | ✓ Complete |
| **Unclaim Tasks** | ✗ Not in spec | ✗ | - |
| **Claim Activities** | ✓ Line 108-110 | ✓ | ✓ Complete |
| **Acknowledge Listings** | ✓ Line 35, 100-104 | ✗ | ✗ MISSING |
| **Per-User Acknowledgment** | ✓ Line 103-104 | ✗ | ✗ MISSING |
| **Activity Completion UI** | ✓ Line 61 | ✗ | ✗ MISSING |
| **Logbook Auto-Movement** | ✓ Line 36, 86 | ✗ | ✗ MISSING |
| **Multi-Assign Tasks** | ✓ Line 116 | ✗ | ✗ MISSING |
| **Task Reassignment** | ✓ Line 183 | ✗ | ✗ MISSING |
| **Activity Sorting (Complete at Bottom)** | ✓ Line 61 | ✗ | ✗ MISSING |
| **Inbox Filtering (By Claim/Acknowledge)** | ✓ Line 127-129 | ⚠️ Partial | ⚠️ Only claim, not acknowledge |

---

## CRITICAL ISSUES

### Issue #1: Listing Acknowledgment Not Implemented
**Severity:** CRITICAL  
**Impact:** Inbox logic is broken - can't track per-user acknowledgment  
**Required:**
- Database table: `listing_acknowledgments(listing_id, staff_id, acknowledged_at)`
- API: `acknowledgeListing(listingId, staffId)`
- Filter: `fetchUnacknowledgedListingsForUser(staffId)`

### Issue #2: "Acknowledge" Button Claims Activities
**Severity:** HIGH  
**Impact:** User can't acknowledge without claiming all work  
**Current Code:** Lines 140-150 in InboxView.swift claim activities instead of acknowledging  
**Required:** Separate acknowledge action that records user intent

### Issue #3: Realtor vs Staff ID Confusion
**Severity:** MEDIUM  
**Impact:** MyListingsStore calls `fetchActivitiesByRealtor(staffId)`  
**Location:** MyListingsStore.swift, line 57  
**Issue:** Method name implies realtorId parameter, but receives staffId  
**Required:** Either rename method or correct the parameter

### Issue #4: No Activity Completion Display
**Severity:** MEDIUM  
**Impact:** Users can't distinguish done from open activities  
**Required:** UI logic to show completed activities at bottom with strikethrough

### Issue #5: No Multi-Assign
**Severity:** MEDIUM  
**Impact:** Can't assign task to multiple people per spec  
**Required:** Change `assignedStaffId` to `assignedStaffIds: [String]`

---

## RECOMMENDATION: Implementation Plan

### Phase 1: Acknowledgment (Critical)
1. Create `listing_acknowledgments` table
2. Add `acknowledgeListing` to repositories
3. Add acknowledgment filtering to InboxStore
4. Fix Inbox context menu (separate acknowledge from claim)

### Phase 2: Activity Completion UI
1. Add sorting/grouping logic to show completed activities at bottom
2. Add strikethrough styling
3. Update ActivityCard component

### Phase 3: Task Reassignment
1. Add `unclaimTask` / `reassignTask` methods
2. Update UI with reassign action
3. Add reassignment history to audit log

### Phase 4: Multi-Assign (if needed per product)
1. Change schema from single staffId to array
2. Update UI to show stacked initials
3. Update claim logic to append instead of replace

---

## FILES REQUIRING CHANGES

**Database (Migrations):**
- New migration: Create `listing_acknowledgments` table
- Update `listings` table schema

**Swift (Repositories):**
- `TaskRepositoryClient.swift` - Add unclaim/reassign methods
- `ListingRepositoryClient.swift` - Add acknowledgment methods
- `TaskRepository.swift` - Update protocol

**Swift (Stores):**
- `InboxStore.swift` - Add acknowledgment filtering
- `MyListingsStore.swift` - Fix realtor/staff ID confusion
- `AllListingsStore.swift` - Add acknowledgment status

**Swift (Views):**
- `InboxView.swift` - Separate acknowledge action from claim
- `ActivityCard.swift` - Add completion styling
- Other activity/listing views - Filter by acknowledgment

**Swift (Models):**
- `ListingWithDetails.swift` - Add acknowledgment status
- `Listing.swift` - Consider acknowledgment fields

---

## CONCLUSION

The codebase implements **task claiming successfully** but has **FUNDAMENTAL GAPS in listing acknowledgment**, which is a core spec requirement. The "Acknowledge" button currently claims activities (wrong semantic), and per-user acknowledgment state is completely absent from the database.

The claimed vs unclaimed model is 40% complete:
- ✓ Task claiming works
- ✗ Acknowledgment is missing (should be 20% of implementation)
- ✗ Unclaim/reassign missing (should be 20%)
- ✗ Activity completion UI missing (should be 15%)
- ✗ Multi-assign missing (should be 5%)

**Next Steps:** Implement acknowledgment system before shipping to production.
