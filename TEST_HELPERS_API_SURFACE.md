# TaskRepositoryTestHelpers API Surface Analysis

## Overview
Complete inventory of mock data patterns, helper functions, and test utilities for TaskRepository testing.

Location: `/Users/noahdeskin/conductor/operations-center/.conductor/miami/apps/Operations Center/Operations CenterTests/Helpers/TaskRepositoryTestHelpers.swift`

---

## 1. TaskRepositoryClient Test Helpers

### Static Instances

#### `.unimplemented`
**Purpose:** Fail-fast repository for tests that shouldn't touch the repository
**Returns:** `TaskRepositoryClient`
**Behavior:** Every method throws `fatalError` if called

**Methods with fatalError:**
- `fetchTasks()`
- `fetchActivities()`
- `fetchDeletedTasks()`
- `fetchDeletedActivities()`
- `claimTask(_:_:)`
- `claimActivity(_:_:)`
- `deleteTask(_:_:)`
- `deleteActivity(_:_:)`
- `fetchTasksByRealtor(_:)`
- `fetchActivitiesByRealtor(_:)`
- `fetchCompletedTasks()`
- `fetchActivitiesByStaff(_:)`

---

### Mock Configuration

#### `.mock(parameters...)`
**Purpose:** Configurable mock repository for testing with full control over behavior

**Parameters:**
```swift
tasks: [TaskWithMessages] = []
activities: [ActivityWithDetails] = []
deletedTasks: [AgentTask] = []
deletedActivities: [ActivityWithDetails] = []
shouldThrow: Bool = false
onClaimTask: @escaping (String) -> Void = { _ in }
onClaimActivity: @escaping (String) -> Void = { _ in }
onDeleteTask: @escaping (String) -> Void = { _ in }
onDeleteActivity: @escaping (String) -> Void = { _ in }
```

**Behavior by Method:**

| Method | Returns | When `shouldThrow` | Callback |
|--------|---------|-------------------|----------|
| `fetchTasks()` | `tasks` parameter | Throws `TestError.mockFailure` | N/A |
| `fetchActivities()` | `activities` parameter | Throws `TestError.mockFailure` | N/A |
| `fetchDeletedTasks()` | `deletedTasks` parameter | Throws `TestError.mockFailure` | N/A |
| `fetchDeletedActivities()` | `deletedActivities` parameter | Throws `TestError.mockFailure` | N/A |
| `fetchTasksByRealtor(_:)` | `tasks` parameter | Throws `TestError.mockFailure` | N/A |
| `fetchActivitiesByRealtor(_:)` | `activities` parameter | Throws `TestError.mockFailure` | N/A |
| `fetchCompletedTasks()` | `deletedTasks.filter { $0.status == .done }` | Throws `TestError.mockFailure` | N/A |
| `fetchActivitiesByStaff(_:)` | `activities` parameter | Throws `TestError.mockFailure` | N/A |
| `claimTask(taskId:staffId:)` | Generated `AgentTask` with `.claimed` status | Throws `TestError.mockFailure` | `onClaimTask(taskId)` |
| `claimActivity(taskId:staffId:)` | Generated `Activity` with `.claimed` status | Throws `TestError.mockFailure` | `onClaimActivity(taskId)` |
| `deleteTask(taskId:staffId:)` | N/A (no return) | Throws `TestError.mockFailure` | `onDeleteTask(taskId)` |
| `deleteActivity(taskId:staffId:)` | N/A (no return) | Throws `TestError.mockFailure` | `onDeleteActivity(taskId)` |

**Claim Return Values:**
- `claimTask` returns: `AgentTask(id: taskId, realtorId: "test-realtor", name: "Claimed Task", status: .claimed, priority: 50, assignedStaffId: staffId, createdAt: Date(), updatedAt: Date())`
- `claimActivity` returns: `Activity(id: taskId, listingId: "test-listing", realtorId: "test-realtor", name: "Claimed Activity", ..., status: .claimed, priority: 50, visibilityGroup: .both, assignedStaffId: staffId, ...)`

---

## 2. Mock Data Builders

### AgentTask.mock()

**Purpose:** Create mock AgentTask instances for testing

**Parameters:**
```swift
id: String = UUID().uuidString
realtorId: String = "test-realtor"
name: String = "Test Task"
description: String? = "Test Description"
taskCategory: TaskCategory? = nil
status: TaskStatus = .open
priority: Int = 50
assignedStaffId: String? = nil
dueDate: Date? = nil
claimedAt: Date? = nil
completedAt: Date? = nil
createdAt: Date = Date()
updatedAt: Date = Date()
deletedAt: Date? = nil
deletedBy: String? = nil
```

**Returns:** `AgentTask`

**Usage Examples:**
```swift
// Default open task
let task = AgentTask.mock()

// Specific realtor
let taskForRealtor = AgentTask.mock(realtorId: "realtor-123")

// Claimed task
let claimedTask = AgentTask.mock(
    status: .claimed,
    assignedStaffId: "staff-456"
)

// Completed task
let doneTask = AgentTask.mock(
    status: .done,
    completedAt: Date()
)

// Deleted task
let deletedTask = AgentTask.mock(
    deletedAt: Date(),
    deletedBy: "staff-789"
)
```

---

### TaskWithMessages.mock()

**Purpose:** Create mock TaskWithMessages (task + associated Slack messages)

**Parameters:**
```swift
id: String = UUID().uuidString
assignedStaffId: String? = nil
status: AgentTask.TaskStatus = .open
messages: [SlackMessage] = []
```

**Returns:** `TaskWithMessages`

**Internal Behavior:**
- Creates underlying `AgentTask` via `AgentTask.mock(id:assignedStaffId:status:)`
- Wraps it with provided messages array
- Default: empty messages array

**Usage Examples:**
```swift
// Task with no messages
let task = TaskWithMessages.mock()

// Task with messages
let taskWithMessages = TaskWithMessages.mock(
    messages: [SlackMessage.mock1, SlackMessage.mock2]
)

// Claimed task with messages
let claimedTask = TaskWithMessages.mock(
    assignedStaffId: "staff-123",
    status: .claimed,
    messages: [SlackMessage.mock1]
)
```

---

### Activity.mock()

**Purpose:** Create mock Activity instances for testing

**Parameters:**
```swift
id: String = UUID().uuidString
listingId: String = "test-listing"
realtorId: String? = "test-realtor"
name: String = "Test Activity"
description: String? = "Test Description"
taskCategory: TaskCategory? = nil
status: TaskStatus = .open
priority: Int = 50
visibilityGroup: VisibilityGroup = .both
assignedStaffId: String? = nil
dueDate: Date? = nil
claimedAt: Date? = nil
completedAt: Date? = nil
createdAt: Date = Date()
updatedAt: Date = Date()
deletedAt: Date? = nil
deletedBy: String? = nil
```

**Returns:** `Activity`

**Special Handling:**
- Always sets `inputs: nil` and `outputs: nil`
- Used as base for `ActivityWithDetails.mock()`

**Usage Examples:**
```swift
// Marketing activity
let marketingActivity = Activity.mock(
    name: "Product Photography",
    taskCategory: .marketing
)

// Admin activity
let adminActivity = Activity.mock(
    name: "CRM Update",
    taskCategory: .admin
)

// Completed activity
let completed = Activity.mock(
    status: .done,
    completedAt: Date()
)
```

---

### ActivityWithDetails.mock()

**Purpose:** Create mock ActivityWithDetails (activity + listing details)

**Parameters:**
```swift
id: String = UUID().uuidString
listingId: String = "test-listing"
assignedStaffId: String? = nil
status: Activity.TaskStatus = .open
listing: Listing? = nil
```

**Returns:** `ActivityWithDetails`

**Internal Behavior:**
- Creates underlying `Activity` via `Activity.mock(id:listingId:assignedStaffId:status:)`
- Creates or uses provided `Listing`
- If `listing` is nil: generates `Listing.mock(id: listingId)`
- Bundles activity + listing

**Usage Examples:**
```swift
// Activity with auto-generated listing
let activity = ActivityWithDetails.mock()

// Activity with custom listing
let customListingActivity = ActivityWithDetails.mock(
    listing: Listing.mock(address: "456 Oak Avenue")
)

// Assigned activity
let assignedActivity = ActivityWithDetails.mock(
    assignedStaffId: "staff-123",
    status: .claimed
)
```

---

### Listing.mock()

**Purpose:** Create mock Listing instances for testing

**Parameters:**
```swift
id: String = UUID().uuidString
address: String = "123 Test St"
city: String = "Test City"
state: String = "CA"
zip: String = "12345"
realtorId: String = "test-realtor"
status: String = "Active"
```

**Returns:** `Listing`

**Fields Always Set To:**
- `photoCount: 0`
- `squareFootage: nil`
- `lotSize: nil`
- `yearBuilt: nil`
- `bedrooms: nil`
- `bathrooms: nil`
- `price: nil`
- `propertyType: nil`
- `createdAt: Date()`
- `updatedAt: Date()`

**Usage Examples:**
```swift
// Default listing
let listing = Listing.mock()

// Custom address
let customListing = Listing.mock(
    address: "789 Elm Street",
    city: "San Francisco",
    zip: "94102"
)

// For specific realtor
let realtorListing = Listing.mock(realtorId: "realtor-xyz")
```

---

## 3. Test Error Types

### TestError Enum

**Location:** Lines 283-286

```swift
enum TestError: Error {
    case mockFailure
    case authFailed
}
```

**Usage:**
- `mockFailure`: Thrown by all repository methods when `shouldThrow: true`
- `authFailed`: Available for authentication-related test failures

**Thrown By:**
- All `TaskRepositoryClient.mock()` methods when `shouldThrow = true`
- Not thrown by `.unimplemented` (uses `fatalError` instead)

---

## 4. Mock Data Patterns in Models

### SlackMessage Mock Variants (In Model)
**File:** `SlackMessage.swift`

Not following `.mock()` pattern. Uses static computed properties instead:
- `SlackMessage.mock1` - message from Sarah Johnson
- `SlackMessage.mock2` - message from Mike Chen

---

### Realtor Mock Variants (In Model)
**File:** `Realtor.swift`

Static mock instances with fixed epoch date (`2024-01-01 00:00:00 UTC`):
- `Realtor.mock1` - Sarah Johnson, active
- `Realtor.mock2` - Michael Chen, active
- `Realtor.mock3` - Jessica Martinez, inactive
- `Realtor.mockList` - Array of all three

---

### ListingNote Mock Variants (In Model)
**File:** `ListingNote.swift`

Static mock instances using relative dates:
- `ListingNote.mock1` - Initial listing prep (2 days ago)
- `ListingNote.mock2` - Photography scheduled (1 day ago)
- `ListingNote.mock3` - Virtual tour request (1 hour ago)

---

### ListingWithActivities Mock Variants (In Model)
**File:** `ListingWithActivities.swift`

Static mock instances:
- `ListingWithActivities.mock1` - listing.mock1 + Activity.mock1 + Activity.mock2
- `ListingWithActivities.mock2` - listing.mock2 + Activity.mock3

---

### Listing Mock Variants (In Model)
**File:** `Listing.swift`

Not explicitly shown, but used by ActivityWithDetails.mock()

---

## 5. Missing Mock Helpers

### NO MOCK FUNCTION FOR:
1. **Staff** - No `.mock()` function exists
2. **ListingWithDetails** - No `.mock()` function exists
3. **ListingWithActivities** - Has static `.mock1/.mock2` but no parametrized `.mock()`
4. **SlackMessage** - Has `.mock1/.mock2` but no parametrized `.mock()`
5. **Realtor** - Has `.mock1/.mock2/.mockList` but no parametrized `.mock()`
6. **ListingNote** - Has `.mock1/.mock2/.mock3` but no parametrized `.mock()`
7. **Listing.mock variants** - Only basic `.mock()`, no `.mock1/.mock2` variants
8. **Activity.mock variants** - Only basic `.mock()`, no predefined `.mock1/.mock2` variants

---

## 6. Pattern Analysis

### Naming Conventions
- **Parametrized builders:** `Type.mock(params...)`
- **Static variants:** `Type.mock1`, `Type.mock2`, `Type.mockList`
- **Callbacks:** `onClaimTask`, `onDeleteTask` (naming pattern: `on[Action][Entity]`)

### Error Handling Patterns
- Repository methods use `shouldThrow` boolean flag
- All methods check and throw `TestError.mockFailure`
- Callback execution happens BEFORE throw (method side effects captured)

### Callback Patterns
- Receive single parameter (ID)
- No return values
- Executed before throw
- Used for: verification that method was called with expected ID

### Mock Data Inheritance
- `TaskWithMessages.mock()` uses `AgentTask.mock()` internally
- `ActivityWithDetails.mock()` uses `Activity.mock()` internally
- `ActivityWithDetails.mock()` uses `Listing.mock()` internally

---

## 7. Complete API Surface Table

| Entity | Parametrized `.mock()` | Static Variants | File Location |
|--------|------------------------|-----------------|----------------|
| TaskRepositoryClient | Yes (configurable) | `.unimplemented` | TaskRepositoryTestHelpers.swift |
| AgentTask | Yes | None | TaskRepositoryTestHelpers.swift |
| TaskWithMessages | Yes | None | TaskRepositoryTestHelpers.swift |
| Activity | Yes | None | TaskRepositoryTestHelpers.swift |
| ActivityWithDetails | Yes | None | TaskRepositoryTestHelpers.swift |
| Listing | Yes | None | TaskRepositoryTestHelpers.swift |
| SlackMessage | No (static only) | `.mock1`, `.mock2` | SlackMessage.swift |
| Realtor | No (static only) | `.mock1`, `.mock2`, `.mock3`, `.mockList` | Realtor.swift |
| ListingNote | No (static only) | `.mock1`, `.mock2`, `.mock3` | ListingNote.swift |
| ListingWithActivities | No (static only) | `.mock1`, `.mock2` | ListingWithActivities.swift |
| Staff | None | None | Staff.swift |
| ListingWithDetails | None | None | ListingWithDetails.swift |
| TestError | N/A | `.mockFailure`, `.authFailed` | TaskRepositoryTestHelpers.swift |

---

## 8. Design Observations

### Strengths
1. PointFree pattern correctly applied (`.unimplemented`, `.mock()`)
2. Callback verification pattern avoids boolean flags
3. Task/Activity composition tested through mock builders
4. Error handling is explicit and testable

### Gaps
1. **Staff** has no mock helper despite being used in assignments
2. **ListingWithDetails** is a composite type but lacks mock builder
3. Inconsistent patterns: Some models use parametrized `.mock()`, others use static variants
4. No `.mock(params...)` for models that are primarily containers (Realtor, ListingNote)
5. SlackMessage mocks are not parametrized despite being used in TaskWithMessages

### Recommendations
1. Add `Staff.mock()` with parameters for role, isActive, etc.
2. Add `ListingWithDetails.mock()` parametrized builder
3. Standardize on parametrized `.mock(params...)` pattern across all entities
4. Add `.mock()` to SlackMessage with controllable content
5. Consider adding `.mock()` to Realtor for better test control
