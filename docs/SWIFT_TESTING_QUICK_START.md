# Swift Testing Research: Key Takeaways

## What You Need to Know

Your codebase is perfectly positioned for Swift Testing. You already have:

1. **@Observable stores** - works naturally with async/await testing
2. **Protocol-based mocks** (MockTaskRepository) - test-ready
3. **Realistic mock data** (TaskMockData) - 5 tasks, 4 activities with proper state
4. **Swift 6 concurrency** - native async/await throughout

## Immediate Actions

### 1. Syntax Overview (2 minutes)
```swift
import Testing

@Suite
struct MyStoreTests {
    @Test("Feature description")
    async func featureName() async throws {
        // Arrange
        let store = MyStore()
        
        // Act
        await store.doSomething()
        
        // Assert
        #expect(store.state == .expected)
    }
}
```

Three key differences from XCTest:
- Use `@Test` instead of `func testName()`
- Use `#expect()` instead of `XCTAssert()`
- Use `async/await` natively (no `XCTestExpectation`)

### 2. Three Core Patterns

**Pattern A: Store Testing**
```swift
@Test
async func storeUpdatesState() async throws {
    let store = MyStore(repository: MockTaskRepository())
    await store.loadData()
    #expect(store.data != nil)
}
```

**Pattern B: Dependency Injection for Mocking**
```swift
// Define protocol
protocol ClientProtocol: Sendable {
    func fetchData() async throws -> [Data]
}

// Create mock
struct MockClient: ClientProtocol { 
    var result: [Data]?
    func fetchData() async throws -> [Data] { 
        result ?? [] 
    }
}

// Inject in store
let store = MyStore(client: MockClient(result: data))
```

**Pattern C: Error Handling**
```swift
@Test
async func handleError() async throws {
    let mockClient = MockClient()
    mockClient.error = NetworkError.offline
    let store = MyStore(client: mockClient)
    
    await store.load()
    
    #expect(store.error != nil)
}
```

### 3. What to Test First (Priority Order)

1. **AuthenticationStore** - isolated, critical path
   - login success/failure
   - signup success/failure
   - logout
   - error states

2. **MockTaskRepository** - already perfect, just add tests
   - claimTask mutation
   - soft delete
   - filtering

3. **Store Logic** - MyTasksStore, AllTasksStore, ListingDetailStore
   - state mutations
   - async flow completion
   - error propagation

### 4. What NOT to Test

- SwiftUI Views (implementation detail, brittle)
- System frameworks (Data, URLSession, etc.)
- Third-party internals (Supabase SDK)
- Trivial getters

### 5. Organization Structure

```
Operations CenterTests/
├── Features/
│   ├── Auth/
│   │   └── AuthenticationStoreTests.swift       ← Start here
│   ├── MyTasks/
│   │   └── MyTasksStoreTests.swift
│   ├── AllTasks/
│   │   └── AllTasksStoreTests.swift
│   └── ListingDetail/
│       └── ListingDetailStoreTests.swift
├── Mocks/
│   ├── MockTaskRepository.swift                 ← You have this ✓
│   ├── MockSupabaseClient.swift                 ← Build this
│   └── TaskMockData.swift                       ← You have this ✓
└── Helpers/
    └── TestHelpers.swift
```

## Code Examples from Your App

### AuthenticationStore Test
```swift
@Suite
struct AuthenticationStoreTests {
    @Test("Login with valid credentials succeeds")
    async func loginSuccess() async throws {
        let mockClient = MockSupabaseClient()
        let store = AuthenticationStore(supabaseClient: mockClient)
        
        await store.login(email: "test@example.com", password: "pass123")
        
        #expect(store.isAuthenticated == true)
        #expect(store.currentUser != nil)
    }
    
    @Test("Invalid credentials shows error")
    async func loginFailure() async throws {
        let mockClient = MockSupabaseClient()
        mockClient.signInError = .invalidCredentials
        let store = AuthenticationStore(supabaseClient: mockClient)
        
        await store.login(email: "test@example.com", password: "wrong")
        
        #expect(store.isAuthenticated == false)
        #expect(store.error != nil)
    }
}
```

### MockTaskRepository Test
```swift
@Suite
struct MockTaskRepositoryTests {
    @Test("Claim task updates status and assignee")
    async func claimTask() async throws {
        let repo = MockTaskRepository()
        
        let claimed = try await repo.claimTask(
            taskId: "agent-task-1",
            staffId: "staff-1"
        )
        
        #expect(claimed.status == .claimed)
        #expect(claimed.assignedStaffId == "staff-1")
    }
    
    @Test("Claiming non-existent task throws")
    async func claimTaskNotFound() async {
        let repo = MockTaskRepository()

        // Verify that attempting to claim nonexistent task throws taskNotFound error
        await #expect(throws: MockRepositoryError.taskNotFound) {
            try await repo.claimTask(
                taskId: "nonexistent",
                staffId: "staff-1"
            )
        }
    }
}
```

## Run Tests

```bash
# All tests
xcodebuild test -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet

# Specific suite
xcodebuild test -scheme "Operations Center" \
  -only-testing "Operations_CenterTests/AuthenticationStoreTests" -quiet
```

## Coverage Target: >80%

Focus on business logic:
- State mutations
- Async flows
- Error handling
- Edge cases (empty results, not found, conflicts)

## Key Files to Create

1. `AuthenticationStoreTests.swift` - Start with this
2. `MockSupabaseClient.swift` - For mocking auth
3. `MyTasksStoreTests.swift` - Use existing MockTaskRepository
4. `ListingDetailStoreTests.swift` - For listing operations

All have concrete examples in the full guide at `docs/SWIFT_TESTING_GUIDE.md`.

## One Critical Insight

Your existing `MockTaskRepository` is already production-grade:
- Uses @MainActor correctly
- Has Sendable conformance
- Uses soft deletes
- Provides mutation tracking

This means you can build store tests immediately without major refactoring. Just add test files that use the mock.

---

**Full details:** See `/docs/SWIFT_TESTING_GUIDE.md` for complete examples, patterns, and build commands.
