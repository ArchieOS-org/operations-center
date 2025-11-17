# Test Helpers Documentation Index

Complete reference for TaskRepositoryTestHelpers.swift and related mock data patterns.

## Documentation Files

### 1. TEST_HELPERS_QUICK_REFERENCE.md
**Best for:** Quick lookup, usage examples, quick decisions
- Parametrized mock builders summary (6 functions)
- TaskRepositoryClient instances (.unimplemented, .mock)
- Test error type
- Composition pattern explanation
- Missing helpers table
- Usage examples with code snippets

**Read this when:** You need to create a mock quickly or remember which mocks exist

### 2. TEST_HELPERS_SIGNATURES.md
**Best for:** Understanding exact signatures, default values, behavior details
- Exact code signatures for all mock builders
- TaskRepositoryClient extension signatures
- Default values summary table
- Return types for all 12 repository methods
- Error throwing behavior explanation

**Read this when:** You need exact parameter lists or want to understand default behavior

### 3. TEST_HELPERS_API_SURFACE.md (This comprehensive document)
**Best for:** Deep dive, understanding patterns, design observations
- 8 detailed sections covering:
  1. TaskRepositoryClient test helpers (unimplemented + mock)
  2. All 5 mock data builders with full parameters
  3. Test error types
  4. Mock data patterns in models
  5. Missing mock helpers (6 entities)
  6. Pattern analysis (naming, error handling, callbacks, composition)
  7. Complete API surface table
  8. Design observations and recommendations

**Read this when:** You need complete understanding or want to add new mocks

---

## Quick Reference by Use Case

### I need to create a mock AgentTask
```swift
let task = AgentTask.mock(
    realtorId: "my-realtor",
    status: .claimed,
    assignedStaffId: "staff-123"
)
```
→ See: TEST_HELPERS_QUICK_REFERENCE.md

### I need to verify a repository method was called
```swift
var claimedTaskId: String?
let repo = TaskRepositoryClient.mock(
    onClaimTask: { id in claimedTaskId = id }
)
```
→ See: TEST_HELPERS_QUICK_REFERENCE.md (Callback section)

### I need to test error handling
```swift
let repo = TaskRepositoryClient.mock(shouldThrow: true)
```
→ See: TEST_HELPERS_SIGNATURES.md (Error Throwing Behavior)

### I need a complex test fixture
```swift
let listing = Listing.mock(address: "123 Main St")
let activity = ActivityWithDetails.mock(listing: listing)
let repo = TaskRepositoryClient.mock(activities: [activity])
```
→ See: TEST_HELPERS_QUICK_REFERENCE.md (Composed mocks example)

### I need to understand the pattern
→ See: TEST_HELPERS_API_SURFACE.md (Section 6: Pattern Analysis)

### I need to add a new mock helper
→ See: TEST_HELPERS_API_SURFACE.md (Section 8: Design Observations and Recommendations)

---

## API Surface Summary

| Category | Count | Examples |
|----------|-------|----------|
| Parametrized Mock Builders | 6 | AgentTask.mock(), Activity.mock() |
| Static Repository Instances | 1 | TaskRepositoryClient.unimplemented |
| Test Error Cases | 2 | .mockFailure, .authFailed |
| Repository Callbacks | 4 | onClaimTask, onDeleteTask |
| Repository Methods Mocked | 12 | fetchTasks, claimActivity, deleteTask |
| Mock Parameters Total | 51 | All optional with smart defaults |
| Missing Mock Helpers | 6 | Staff, ListingWithDetails, SlackMessage.mock() |
| Composition Levels | 2-3 | TaskWithMessages → AgentTask |

---

## Key Patterns

### 1. All Parameters Are Optional
```swift
// Every mock builder works with all defaults
let task = AgentTask.mock()
```

### 2. Smart Default Values
```swift
AgentTask.mock(
    // id: String = UUID().uuidString  (unique each time)
    // realtorId: String = "test-realtor"
    // status: TaskStatus = .open
    // priority: Int = 50
)
```

### 3. Composition Chain
```
TaskWithMessages.mock()
  └─ AgentTask.mock()          (creates task)
  └─ [SlackMessage]            (provided or default [])

ActivityWithDetails.mock()
  └─ Activity.mock()           (creates activity)
  └─ Listing.mock()            (auto-generates or uses provided)
```

### 4. Error Control via shouldThrow
```swift
// Normal behavior
let repo = TaskRepositoryClient.mock()

// Error scenario
let repo = TaskRepositoryClient.mock(shouldThrow: true)
// All methods throw TestError.mockFailure
```

### 5. Callback Verification
```swift
var methodWasCalled = false
let repo = TaskRepositoryClient.mock(
    onClaimTask: { _ in methodWasCalled = true }
)
// Callback executes BEFORE throw (side effects preserved)
```

---

## Entity Coverage

### Fully Supported (Parametrized .mock())
- AgentTask
- TaskWithMessages
- Activity
- ActivityWithDetails
- Listing
- TaskRepositoryClient

### Partially Supported (Static variants only)
- SlackMessage (.mock1, .mock2)
- Realtor (.mock1, .mock2, .mock3, .mockList)
- ListingNote (.mock1, .mock2, .mock3)
- ListingWithActivities (.mock1, .mock2)

### Unsupported (No mocks)
- Staff
- ListingWithDetails

---

## Testing Patterns

### Simple Unit Test
```swift
let task = AgentTask.mock()
// Use task in test
```

### Fixture with Custom Data
```swift
let listing = Listing.mock(address: "456 Oak Ave")
let activity = ActivityWithDetails.mock(listing: listing)
// Test with custom listing
```

### Error Scenario
```swift
let repo = TaskRepositoryClient.mock(shouldThrow: true)
XCTAssertThrowsError(try await repo.fetchTasks())
```

### Method Call Verification
```swift
var claimedId: String?
let repo = TaskRepositoryClient.mock(
    onClaimTask: { id in claimedId = id }
)
_ = try await repo.claimTask("task-123", "staff-456")
XCTAssertEqual(claimedId, "task-123")
```

### Repository State Setup
```swift
let repo = TaskRepositoryClient.mock(
    tasks: [TaskWithMessages.mock(), TaskWithMessages.mock()],
    activities: [ActivityWithDetails.mock()],
    shouldThrow: false
)
// Test with pre-configured data
```

---

## Design Notes

### Strengths
1. **PointFree Pattern** - .unimplemented and .mock properly implement the pattern
2. **Callback Verification** - Elegant way to verify method calls
3. **Composition** - Mock builders nest properly
4. **All Optional** - No required parameters, always usable
5. **Smart Defaults** - Sensible test values (UUID, "test-realtor", etc.)

### Known Gaps
1. **Staff Missing** - Used in assignments but no mock helper
2. **ListingWithDetails Missing** - Composite type without builder
3. **Inconsistent Patterns** - Some models use .mock(), others use static variants
4. **Limited SlackMessage** - Only 2 pre-built variants, can't customize
5. **Limited Realtor** - 3 variants but can't build arbitrary mock

### Recommendations for Future
1. Add `Staff.mock()` with role and isActive parameters
2. Add `ListingWithDetails.mock()` parametrized builder
3. Standardize all entities to use `.mock(params...)` pattern
4. Add parametrized `.mock()` to SlackMessage
5. Add parametrized `.mock()` to Realtor

---

## File Locations

**Main Test Helpers:**
`/apps/Operations Center/Operations CenterTests/Helpers/TaskRepositoryTestHelpers.swift`

**Related Mock Data:**
- `/apps/Operations Center/Packages/OperationsCenterKit/Sources/OperationsCenterKit/Models/SlackMessage.swift`
- `/apps/Operations Center/Packages/OperationsCenterKit/Sources/OperationsCenterKit/Models/Realtor.swift`
- `/apps/Operations Center/Packages/OperationsCenterKit/Sources/OperationsCenterKit/Models/ListingNote.swift`
- `/apps/Operations Center/Packages/OperationsCenterKit/Sources/OperationsCenterKit/Models/ListingWithActivities.swift`
- `/apps/Operations Center/Packages/OperationsCenterKit/Sources/OperationsCenterKit/Models/Staff.swift` (no mock)
- `/apps/Operations Center/Packages/OperationsCenterKit/Sources/OperationsCenterKit/Models/ListingWithDetails.swift` (no mock)

---

## Version History

Last updated: November 17, 2025
- Complete API surface documented
- All 6 mock builders catalogued
- All 12 repository methods behavior mapped
- All 6 missing helpers identified
- Pattern analysis completed
