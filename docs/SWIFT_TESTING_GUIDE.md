# Swift Testing Framework: Research & Best Practices

## Executive Summary

Swift Testing is the modern replacement for XCTest. It provides expressive APIs, macro-powered syntax, and superior async/await support. Your codebase is perfectly positioned to adopt it—you already have the foundation with `@Observable` stores, dependency injection via swift-dependencies, and proper protocol-based mocking.

**Target Completion:** >80% coverage on business logic (stores, repositories, authentication)

---

## 1. Swift Testing Fundamentals

### Core Syntax

```swift
import Testing

// Simplest test possible
@Test
func example() async throws {
    let result = 42
    #expect(result == 42)
}

// Test with clear name and description
@Test("User can claim an unclaimed task")
async func claimTask() throws {
    // Arrange
    let repository = MockTaskRepository()
    let task = try await repository.claimTask(taskId: "123", staffId: "staff-1")
    
    // Assert
    #expect(task.status == .claimed)
    #expect(task.assignedStaffId == "staff-1")
}
```

**Key differences from XCTest:**

| Feature | Swift Testing | XCTest |
|---------|---------------|--------|
| Syntax | `@Test` macro | `func testExample()` |
| Assertions | `#expect(condition)` | `XCTAssert...()` |
| Async | Native `async/await` | Requires `XCTestExpectation` |
| Organization | `struct` tests | `class` subclassing |
| Parameterization | Built-in with `@Test` | Requires loops/subtests |

### Test Organization

```swift
struct MyFeatureTests {
    // Group related tests logically
    
    @Test("Happy path: load data successfully")
    async func loadDataSuccess() throws { }
    
    @Test("Error path: handle network failure")
    async func loadDataNetworkError() throws { }
    
    @Test("Edge case: empty result set")
    async func loadDataEmpty() throws { }
}
```

**Why struct, not class?**
- Value semantics = no shared state between tests
- Lighter weight
- Clearer intent: each test is independent

---

## 2. Testing @Observable Stores

Your stores use `@Observable` from Swift 5.9+. This is the modern pattern and works perfectly with Swift Testing.

### Pattern: Store Testing Setup

```swift
import Testing
import Observation

@Suite
struct AuthenticationStoreTests {
    // MARK: - Setup
    
    // Create a mock Supabase client that you can control
    private let mockSupabaseClient = MockSupabaseClient()
    
    // MARK: - Tests
    
    @Test("Login succeeds with valid credentials")
    async func loginSuccess() throws {
        // Arrange
        let store = AuthenticationStore(supabaseClient: mockSupabaseClient)
        mockSupabaseClient.mockLoginSuccess(user: testUser)
        
        // Act
        await store.login(email: "test@example.com", password: "password")
        
        // Assert
        #expect(store.isAuthenticated == true)
        #expect(store.currentUser?.id == testUser.id)
        #expect(store.error == nil)
    }
    
    @Test("Login fails with invalid credentials")
    async func loginInvalidCredentials() async throws {
        // Arrange
        let store = AuthenticationStore(supabaseClient: mockSupabaseClient)
        mockSupabaseClient.mockLoginFailure(error: .invalidCredentials)
        
        // Act
        await store.login(email: "test@example.com", password: "wrong")
        
        // Assert
        #expect(store.isAuthenticated == false)
        #expect(store.error == .invalidCredentials)
        #expect(store.currentUser == nil)
    }
    
    @Test("Logout clears authentication state")
    async func logoutClearsState() async throws {
        // Arrange
        let store = AuthenticationStore(supabaseClient: mockSupabaseClient)
        await store.login(email: "test@example.com", password: "password")
        
        // Act
        await store.logout()
        
        // Assert
        #expect(store.isAuthenticated == false)
        #expect(store.currentUser == nil)
        #expect(store.error == nil)
    }
}
```

### Key Pattern: Observation

When testing `@Observable` stores:

1. **No need for `withObservationTracking`** - just read the property
2. **Async/await works naturally** - mutations happen in `@MainActor` context
3. **State changes are synchronous** - check them immediately after the action

```swift
@Test
async func storeUpdatesImmediately() async throws {
    let store = MyStore()
    
    // Call async method
    await store.loadData()
    
    // Synchronously check the result (already finished)
    #expect(store.data != nil)
    #expect(store.isLoading == false)
}
```

---

## 3. Dependency Injection for Testing

Your codebase uses **swift-dependencies** for DI. This is perfect for testing because you can inject mocks.

### Pattern: Protocol-Based Mocking

```swift
// 1. Define the protocol (your source of truth)
protocol SupabaseClientProtocol: Sendable {
    func fetchTasks() async throws -> [AgentTask]
    func claimTask(_ id: String, staff: String) async throws -> AgentTask
}

// 2. Real implementation (production)
struct SupabaseClient: SupabaseClientProtocol {
    // Real implementation
}

// 3. Mock implementation (testing)
struct MockSupabaseClient: SupabaseClientProtocol {
    var fetchTasksResult: [AgentTask]?
    var fetchTasksError: Error?
    var claimTaskResult: AgentTask?
    var claimTaskError: Error?
    
    func fetchTasks() async throws -> [AgentTask] {
        if let error = fetchTasksError {
            throw error
        }
        return fetchTasksResult ?? []
    }
    
    func claimTask(_ id: String, staff: String) async throws -> AgentTask {
        if let error = claimTaskError {
            throw error
        }
        guard let result = claimTaskResult else {
            throw NSError(domain: "Mock", code: -1)
        }
        return result
    }
}

// 4. Inject in your store
@Observable
final class MyStore {
    private let client: SupabaseClientProtocol
    
    init(client: SupabaseClientProtocol) {
        self.client = client
    }
}

// 5. Test with mock
@Test
async func testWithMock() throws {
    let mockClient = MockSupabaseClient()
    mockClient.claimTaskResult = AgentTask(...) // Set expected result
    
    let store = MyStore(client: mockClient)
    // Test store behavior
}
```

### Your Current Pattern: Already Perfect

Your `MockTaskRepository` is exactly this pattern:

```swift
// In your codebase (GOOD):
@MainActor
final class MockTaskRepository: TaskRepository {
    func claimTask(taskId: String, staffId: String) async throws -> AgentTask {
        // Can test this easily
    }
}

// Tests would be:
@Test
async func claimTask() async throws {
    let repository = MockTaskRepository()
    let result = try await repository.claimTask(taskId: "123", staffId: "staff-1")
    #expect(result.status == .claimed)
}
```

---

## 4. Testing Async Flows

Swift Testing has native async/await support. No more `XCTestExpectation` complexity.

### Pattern: Async/Await Tests

```swift
@Test
async func loadDataAsyncFlow() async throws {
    // Setup
    let mockClient = MockSupabaseClient()
    let store = MyStore(client: mockClient)
    
    // Act (all async operations finish before next line)
    await store.loadData()
    
    // Assert (data is already loaded)
    #expect(store.data != nil)
    #expect(store.isLoading == false)
}
```

### Pattern: Error Handling

```swift
@Test
async func loadDataThrowsNetworkError() async throws {
    // Setup
    let mockClient = MockSupabaseClient()
    mockClient.fetchTasksError = NetworkError.noConnection
    let store = MyStore(client: mockClient)
    
    // Act
    await store.loadData()
    
    // Assert
    #expect(store.error != nil)
    #expect(store.data == nil)
}

// For sync errors, use Swift Testing's error expectations:
@Test
async func parseInvalidJSON() throws {
    let decoder = JSONDecoder()
    let invalidData = "not json".data(using: .utf8)!
    
    // Will automatically fail if no error is thrown
    _ = try decoder.decode(MyModel.self, from: invalidData)
}
```

### Pattern: Timing & Delays

```swift
// If you need to test behavior over time:
@Test
async func loadDataWithDelay() async throws {
    let store = MyStore()
    
    // Act: start load
    let loadTask = Task { await store.loadData() }
    
    // Assert: still loading
    #expect(store.isLoading == true)
    
    // Wait for completion
    await loadTask.value
    
    // Assert: now loaded
    #expect(store.isLoading == false)
}
```

---

## 5. Testing Patterns from Your Codebase

### Existing: MockTaskRepository

Your mock is well-structured. Here's how to test it:

```swift
@Suite
struct MyTasksStoreTests {
    @Test
    async func fetchTasksReturnsFiltered() async throws {
        // You have TaskMockData with 5 realistic tasks
        let repository = MockTaskRepository()
        
        let tasks = try await repository.fetchTasks()
        
        #expect(tasks.count == 5)
        #expect(tasks.allSatisfy { $0.task.deletedAt == nil })
    }
    
    @Test
    async func claimTaskUpdatesState() async throws {
        let repository = MockTaskRepository()
        
        let claimed = try await repository.claimTask(
            taskId: "agent-task-1",
            staffId: "staff-1"
        )
        
        #expect(claimed.status == .claimed)
        #expect(claimed.assignedStaffId == "staff-1")
    }
    
    @Test("Claiming non-existent task throws")
    async func claimTaskNotFound() async throws {
        let repository = MockTaskRepository()
        
        // Should throw MockRepositoryError.taskNotFound
        let task = try await repository.claimTask(
            taskId: "nonexistent",
            staffId: "staff-1"
        )
        // This line won't execute because above throws
    }
}
```

---

## 6. What NOT to Test

Time is finite. Focus on business logic (>80% coverage goal).

### DON'T Test
- SwiftUI views themselves (views are disposable)
- System frameworks (UIView, Data, etc.)
- Third-party libraries (Supabase SDK internals)
- Trivial getters/setters

### DO Test
- Store logic (state mutations, async flows)
- Authentication flows (login, signup, logout, error handling)
- Repository operations (claim, delete, filtering)
- Model validation
- Error handling paths
- Edge cases (empty results, duplicates, expired sessions)

### Example: What to prioritize

```swift
// YES: Business logic
@Test
async func myTasksStoreFiltersUnclaimedTasks() async throws {
    let repository = MockTaskRepository()
    let store = MyTasksStore(repository: repository)
    
    await store.loadTasks()
    
    #expect(store.unclaimedTasks.allSatisfy { $0.assignedStaffId == nil })
}

// NO: UI details
@Test
func myTasksViewRendersCorrectly() throws {
    // Don't test View rendering - it's implementation detail
}
```

---

## 7. Test Organization Structure

Based on your project layout:

```
Operations Center/
├── Operations CenterTests/
│   ├── Features/
│   │   ├── Auth/
│   │   │   └── AuthenticationStoreTests.swift
│   │   ├── MyTasks/
│   │   │   └── MyTasksStoreTests.swift
│   │   ├── AllTasks/
│   │   │   └── AllTasksStoreTests.swift
│   │   └── ListingDetail/
│   │       └── ListingDetailStoreTests.swift
│   ├── Mocks/
│   │   ├── MockTaskRepository.swift ✓ (you have this)
│   │   ├── MockSupabaseClient.swift
│   │   ├── MockAuthClient.swift
│   │   └── TaskMockData.swift ✓ (you have this)
│   └── Helpers/
│       ├── TestHelpers.swift
│       └── XCTestDynamicOverlay.swift (if needed)
```

---

## 8. Concrete Testing Examples from Your App

### Example 1: Authentication Store

```swift
import Testing

@Suite
struct AuthenticationStoreTests {
    let mockSupabaseClient = MockSupabaseClient()
    
    @Test("User logs in successfully")
    async func userLogsInSuccessfully() async throws {
        // Arrange
        let store = AuthenticationStore(supabaseClient: mockSupabaseClient)
        mockSupabaseClient.mockUser = User(id: "user-1", email: "test@example.com")
        
        // Act
        await store.login(email: "test@example.com", password: "password123")
        
        // Assert
        #expect(store.isAuthenticated == true)
        #expect(store.currentUser?.email == "test@example.com")
        #expect(store.isLoading == false)
    }
    
    @Test("User signs up with team selection")
    async func userSignsUp() async throws {
        let store = AuthenticationStore(supabaseClient: mockSupabaseClient)
        
        await store.signup(
            email: "newuser@example.com",
            password: "password123",
            team: .marketing
        )
        
        #expect(store.isAuthenticated == true)
        #expect(store.currentUser?.email == "newuser@example.com")
    }
    
    @Test("Email already in use error is handled")
    async func emailAlreadyInUseError() async throws {
        let store = AuthenticationStore(supabaseClient: mockSupabaseClient)
        mockSupabaseClient.signupError = AuthError.emailAlreadyInUse
        
        await store.signup(
            email: "existing@example.com",
            password: "password123",
            team: .admin
        )
        
        #expect(store.error == AuthError.emailAlreadyInUse)
        #expect(store.isAuthenticated == false)
    }
}
```

### Example 2: Task List Store

```swift
@Suite
struct MyTasksStoreTests {
    let mockRepository = MockTaskRepository()
    
    @Test("Load tasks filters out deleted tasks")
    async func loadTasksFiltersDeleted() async throws {
        let store = MyTasksStore(repository: mockRepository)
        
        await store.loadTasks()
        
        #expect(store.tasks.allSatisfy { $0.deletedAt == nil })
    }
    
    @Test("User can claim a task")
    async func claimTask() async throws {
        let store = MyTasksStore(repository: mockRepository)
        let taskId = "agent-task-1"
        let staffId = "staff-1"
        
        await store.claimTask(taskId: taskId, staffId: staffId)
        
        let claimedTask = store.tasks.first(where: { $0.id == taskId })
        #expect(claimedTask?.status == .claimed)
        #expect(claimedTask?.assignedStaffId == staffId)
    }
    
    @Test("Loading state updates correctly")
    async func loadingStateUpdates() async throws {
        let store = MyTasksStore(repository: mockRepository)
        
        #expect(store.isLoading == false)
        
        let loadTask = Task { await store.loadTasks() }
        #expect(store.isLoading == true) // May be false if very fast
        
        await loadTask.value
        #expect(store.isLoading == false)
    }
    
    @Test("Empty task list handled gracefully")
    async func emptyTaskList() async throws {
        let mockRepo = MockTaskRepository()
        // mockRepo.tasks = [] // If you add this capability
        let store = MyTasksStore(repository: mockRepo)
        
        await store.loadTasks()
        
        #expect(store.tasks.isEmpty)
    }
}
```

### Example 3: Listing Detail Store

```swift
@Suite
struct ListingDetailStoreTests {
    let mockRepository = MockTaskRepository()
    
    @Test("Load listing details with activities")
    async func loadListingWithActivities() async throws {
        let store = ListingDetailStore(
            listingId: "listing-001",
            repository: mockRepository
        )
        
        await store.loadListing()
        
        #expect(store.listing != nil)
        #expect(store.listing?.id == "listing-001")
        #expect(store.activities.isEmpty == false)
    }
    
    @Test("Activities are filtered by listing")
    async func activitiesAreFiltered() async throws {
        let store = ListingDetailStore(
            listingId: "listing-001",
            repository: mockRepository
        )
        
        await store.loadListing()
        
        #expect(store.activities.allSatisfy { $0.listing.id == "listing-001" })
    }
}
```

---

## 9. Swift Testing Features You Should Use

### 1. Parameterized Tests

```swift
@Test(arguments: [
    ("validEmail@test.com", true),
    ("invalidEmail", false),
    ("", false),
    ("user@", false)
])
func validateEmail(email: String, expectedValid: Bool) throws {
    let result = isValidEmail(email)
    #expect(result == expectedValid)
}
```

### 2. Test Tags/Organization

```swift
@Suite(.serialized) // Run these tests in order
struct CriticalAuthTests {
    @Test
    async func step1_UserSignsUp() { }
    
    @Test
    async func step2_UserLogsIn() { }
}
```

### 3. Comments for Complex Tests

```swift
@Test
async func complexWorkflow() async throws {
    // This test verifies the entire task claim workflow:
    // 1. User sees unassigned task
    // 2. User claims task (sets assignedStaffId)
    // 3. Task status changes to .claimed
    // 4. Task appears in "My Tasks" list
    
    let repository = MockTaskRepository()
    let store = MyTasksStore(repository: repository)
    
    await store.loadTasks()
    let initialUnassigned = store.unclaimedTasks
    
    await store.claimTask(taskId: "agent-task-1", staffId: "staff-1")
    
    #expect(initialUnassigned.count > store.unclaimedTasks.count)
    #expect(store.claimedTasks.first?.id == "agent-task-1")
}
```

---

## 10. Build & Run Tests

```bash
# Run all tests
xcodebuild test \
  -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.5' \
  -quiet

# Run specific test suite
xcodebuild test \
  -scheme "Operations Center" \
  -only-testing "Operations_CenterTests/AuthenticationStoreTests" \
  -quiet

# Run and show failures only
xcodebuild test \
  -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.5' \
  2>&1 | grep -E "(Test Suite|FAILED|passed)"
```

---

## 11. Coverage Target: >80% for Business Logic

Focus on these critical paths first:

1. **Authentication (AuthenticationStore)**
   - Login success/failure
   - Signup success/failure  
   - Logout
   - Session restoration
   - Error handling

2. **Task Management (MyTasksStore, AllTasksStore)**
   - Load tasks
   - Claim task
   - Delete task
   - Filter operations

3. **Listing Management (ListingDetailStore)**
   - Load listing
   - Load activities for listing
   - Update listing

4. **Error Scenarios**
   - Network failures
   - Invalid input
   - Not found errors
   - Permission errors

---

## 12. Quick Reference: Swift Testing vs XCTest

```swift
// XCTest (old)
import XCTest

class MyTests: XCTestCase {
    func testExample() throws {
        XCTAssert(true)
    }
}

// Swift Testing (new)
import Testing

struct MyTests {
    @Test
    func example() throws {
        #expect(true)
    }
}
```

Key advantages of Swift Testing:
- No class inheritance
- No setup/teardown methods (use init/deinit if needed)
- Direct async/await support
- Automatic test discovery (no `test` prefix required)
- Better error messages
- Parameterization built-in
- Tags/organization with `@Suite`

---

## Next Steps

1. **Start with authentication tests** (isolated, fewer dependencies)
2. **Move to repository tests** (mock data already exists)
3. **Build store tests** (higher level, test business logic)
4. **Gradually increase coverage** to 80%+
5. **Refactor as you learn** - test structure will improve

Your codebase is in excellent shape for testing. The combination of:
- `@Observable` stores
- Protocol-based repositories  
- Existing mock data
- Swift 6 concurrency

...means you can achieve 80%+ coverage efficiently.

**Key insight from your existing code:** Your `MockTaskRepository` and `TaskMockData` are already production-grade mocks. Build tests around them immediately.

