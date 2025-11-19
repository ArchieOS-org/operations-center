# Test Helpers Quick Reference

## Parametrized Mock Builders (From TaskRepositoryTestHelpers.swift)

### Entities with `.mock(params...)` pattern:
1. **AgentTask.mock()** - 14 parameters, all optional with smart defaults
2. **TaskWithMessages.mock()** - 4 parameters (id, assignedStaffId, status, messages)
3. **Activity.mock()** - 16 parameters, matching AgentTask + visibilityGroup
4. **ActivityWithDetails.mock()** - 5 parameters (id, listingId, assignedStaffId, status, listing)
5. **Listing.mock()** - 6 parameters (id, address, city, state, zip, realtorId, status)

### TaskRepositoryClient instances:
- `.unimplemented` - Fail-fast, every method throws fatalError
- `.mock(params...)` - Configurable with 8 parameters:
  - Data: tasks, activities, deletedTasks, deletedActivities
  - Behavior: shouldThrow
  - Callbacks: onClaimTask, onClaimActivity, onDeleteTask, onDeleteActivity

## Test Error

```swift
enum TestError: Error {
    case mockFailure      // Thrown by mock when shouldThrow=true
    case authFailed       // Available for auth tests
}
```

## Composition Pattern

```
TaskWithMessages.mock()
  └─ AgentTask.mock()
  └─ [SlackMessage] (provided)

ActivityWithDetails.mock()
  └─ Activity.mock()
  └─ Listing.mock() (auto-generated or provided)
```

## Callback Execution Order

In `TaskRepositoryClient.mock()`:
1. Check `shouldThrow`
2. Execute callback (if applicable)
3. Return result or throw

## Missing Helpers

| Entity | Gap | Workaround |
|--------|-----|-----------|
| Staff | No `.mock()` | Use constructor directly, add helper if needed |
| ListingWithDetails | No `.mock()` | Use constructor directly, add helper if needed |
| SlackMessage | No parametrized `.mock()` | Use `.mock1`, `.mock2` or create new instances |
| Realtor | No parametrized `.mock()` | Use `.mock1`, `.mock2`, `.mock3`, or `.mockList` |
| ListingNote | No parametrized `.mock()` | Use `.mock1`, `.mock2`, `.mock3` from model |
| ListingWithActivities | No parametrized `.mock()` | Use `.mock1`, `.mock2` from model |

## Usage Pattern Examples

### Simple mock
```swift
let task = AgentTask.mock()
let activity = Activity.mock()
let listing = Listing.mock()
```

### Configured mock
```swift
let repo = TaskRepositoryClient.mock(
    tasks: [TaskWithMessages.mock()],
    shouldThrow: true
)
```

### With callbacks
```swift
var claimedTaskId: String?
let repo = TaskRepositoryClient.mock(
    onClaimTask: { id in claimedTaskId = id }
)
```

### Composed mocks
```swift
let listing = Listing.mock(address: "123 Main St")
let activity = ActivityWithDetails.mock(listing: listing)
```
