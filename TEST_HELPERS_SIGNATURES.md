# Test Helpers - Exact Code Signatures

## TaskRepositoryClient Extensions

### Static Instance: unimplemented
```swift
extension TaskRepositoryClient {
    static var unimplemented: Self {
        // Every method throws fatalError
    }
}
```

### Static Function: mock
```swift
extension TaskRepositoryClient {
    static func mock(
        tasks: [TaskWithMessages] = [],
        activities: [ActivityWithDetails] = [],
        deletedTasks: [AgentTask] = [],
        deletedActivities: [ActivityWithDetails] = [],
        shouldThrow: Bool = false,
        onClaimTask: @escaping (String) -> Void = { _ in },
        onClaimActivity: @escaping (String) -> Void = { _ in },
        onDeleteTask: @escaping (String) -> Void = { _ in },
        onDeleteActivity: @escaping (String) -> Void = { _ in }
    ) -> Self
}
```

## Entity Mock Builders

### AgentTask.mock()
```swift
extension AgentTask {
    static func mock(
        id: String = UUID().uuidString,
        realtorId: String = "test-realtor",
        name: String = "Test Task",
        description: String? = "Test Description",
        taskCategory: TaskCategory? = nil,
        status: TaskStatus = .open,
        priority: Int = 50,
        assignedStaffId: String? = nil,
        dueDate: Date? = nil,
        claimedAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        deletedBy: String? = nil
    ) -> AgentTask
}
```

### TaskWithMessages.mock()
```swift
extension TaskWithMessages {
    static func mock(
        id: String = UUID().uuidString,
        assignedStaffId: String? = nil,
        status: AgentTask.TaskStatus = .open,
        messages: [SlackMessage] = []
    ) -> TaskWithMessages
}
```

### Activity.mock()
```swift
extension Activity {
    static func mock(
        id: String = UUID().uuidString,
        listingId: String = "test-listing",
        realtorId: String? = "test-realtor",
        name: String = "Test Activity",
        description: String? = "Test Description",
        taskCategory: TaskCategory? = nil,
        status: TaskStatus = .open,
        priority: Int = 50,
        visibilityGroup: VisibilityGroup = .both,
        assignedStaffId: String? = nil,
        dueDate: Date? = nil,
        claimedAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        deletedBy: String? = nil
    ) -> Activity
}
```

### ActivityWithDetails.mock()
```swift
extension ActivityWithDetails {
    static func mock(
        id: String = UUID().uuidString,
        listingId: String = "test-listing",
        assignedStaffId: String? = nil,
        status: Activity.TaskStatus = .open,
        listing: Listing? = nil
    ) -> ActivityWithDetails
}
```

### Listing.mock()
```swift
extension Listing {
    static func mock(
        id: String = UUID().uuidString,
        address: String = "123 Test St",
        city: String = "Test City",
        state: String = "CA",
        zip: String = "12345",
        realtorId: String = "test-realtor",
        status: String = "Active"
    ) -> Listing
}
```

## Test Error Type
```swift
enum TestError: Error {
    case mockFailure
    case authFailed
}
```

## Default Values Summary

| Type | Key Defaults |
|------|--------------|
| AgentTask | id: UUID(), realtorId: "test-realtor", status: .open, priority: 50 |
| TaskWithMessages | id: UUID(), status: .open, messages: [] |
| Activity | id: UUID(), listingId: "test-listing", status: .open, priority: 50 |
| ActivityWithDetails | id: UUID(), listingId: "test-listing", status: .open |
| Listing | id: UUID(), address: "123 Test St", city: "Test City", state: "CA", zip: "12345" |
| TaskRepositoryClient.mock | tasks: [], activities: [], shouldThrow: false |

## Return Types from TaskRepositoryClient.mock Closures

| Method | Return Type | Default Behavior |
|--------|------------|-----------------|
| fetchTasks | [TaskWithMessages] | Returns `tasks` parameter |
| fetchActivities | [ActivityWithDetails] | Returns `activities` parameter |
| fetchDeletedTasks | [AgentTask] | Returns `deletedTasks` parameter |
| fetchDeletedActivities | [ActivityWithDetails] | Returns `deletedActivities` parameter |
| claimTask | AgentTask | Returns new AgentTask(id: taskId, status: .claimed, assignedStaffId: staffId) |
| claimActivity | Activity | Returns new Activity(id: taskId, status: .claimed, assignedStaffId: staffId) |
| deleteTask | Void | Calls onDeleteTask(taskId) |
| deleteActivity | Void | Calls onDeleteActivity(taskId) |
| fetchTasksByRealtor | [TaskWithMessages] | Returns `tasks` parameter |
| fetchActivitiesByRealtor | [ActivityWithDetails] | Returns `activities` parameter |
| fetchCompletedTasks | [AgentTask] | Returns deletedTasks.filter { $0.status == .done } |
| fetchActivitiesByStaff | [ActivityWithDetails] | Returns `activities` parameter |

## Error Throwing Behavior

When `shouldThrow = true` in `TaskRepositoryClient.mock()`:
- All fetch methods throw `TestError.mockFailure` 
- All mutation methods (claim, delete) throw `TestError.mockFailure` AFTER executing callback
- Callbacks execute before throw (side effects preserved)

When `shouldThrow = false` (default):
- All methods return normally
- Callbacks execute normally
- No exceptions thrown
