//
//  MyTasksStoreTests.swift
//  Operations Center Tests
//
//  Comprehensive test suite for MyTasksStore - user-specific task filtering
//

import Testing
import Foundation
import Dependencies
import OperationsCenterKit
@testable import Operations_Center

// MARK: - Initial State Tests

@Suite("MyTasksStore - Initial State", .serialized)
@MainActor
struct MyTasksStoreInitialStateTests {

    @Test("Initial state has empty arrays and no errors")
    func initialState() {
        let repo = TaskRepositoryClient.mock()
        let store = MyTasksStore(repository: repo)

        #expect(store.tasks.isEmpty)
        #expect(store.expandedTaskId == nil)
        #expect(store.isLoading == false)
        #expect(store.errorMessage == nil)
    }

    @Test("Can initialize with preview data")
    func initializeWithPreviewData() {
        let repo = TaskRepositoryClient.mock()
        let mockTasks = [AgentTask.mock(id: "task-1")]
        let store = MyTasksStore(repository: repo, initialTasks: mockTasks)

        #expect(store.tasks.count == 1)
        #expect(store.tasks[0].id == "task-1")
    }
}

// MARK: - Fetch Tests

@Suite("MyTasksStore - Fetch Tasks", .serialized)
@MainActor
struct MyTasksStoreFetchTests {

    @Test("Fetch filters for current user's claimed tasks")
    func fetchFiltersForCurrentUser() async {
        let mockTasks: [TaskWithMessages] = [
            .mock(id: "task-1", status: .claimed, assignedStaffId: "user-123"),
            .mock(id: "task-2", status: .inProgress, assignedStaffId: "user-123"),
            .mock(id: "task-3", status: .claimed, assignedStaffId: "other-user"),
            .mock(id: "task-4", status: .open, assignedStaffId: nil),
            .mock(id: "task-5", status: .open, assignedStaffId: "user-123")
        ]
        let repo = TaskRepositoryClient.mock(tasks: mockTasks)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        // Should only show task-1 and task-2 (user-123 + claimed/inProgress)
        #expect(store.tasks.count == 2)
        let taskIds = Set(store.tasks.map { $0.id })
        #expect(taskIds.contains("task-1"))
        #expect(taskIds.contains("task-2"))
        #expect(!taskIds.contains("task-3")) // Different user
        #expect(!taskIds.contains("task-4")) // No assignee
        #expect(!taskIds.contains("task-5")) // Wrong status
    }

    @Test("Fetch only includes claimed and in-progress statuses")
    func fetchFiltersForValidStatuses() async {
        let mockTasks: [TaskWithMessages] = [
            .mock(id: "task-1", status: .claimed, assignedStaffId: "user-123"),
            .mock(id: "task-2", status: .inProgress, assignedStaffId: "user-123"),
            .mock(id: "task-3", status: .open, assignedStaffId: "user-123"),
            .mock(id: "task-4", status: .done, assignedStaffId: "user-123"),
            .mock(id: "task-5", status: .cancelled, assignedStaffId: "user-123")
        ]
        let repo = TaskRepositoryClient.mock(tasks: mockTasks)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        // Should only show task-1 and task-2
        #expect(store.tasks.count == 2)
        let taskIds = Set(store.tasks.map { $0.id })
        #expect(taskIds.contains("task-1"))
        #expect(taskIds.contains("task-2"))
    }

    @Test("Fetch sets loading state during operation")
    func fetchLoadingState() async {
        // Create a continuation to control when the mock fetch completes
        var continuation: CheckedContinuation<Void, Never>?
        var continuationReady = false

        let repo = TaskRepositoryClient.mock(
            onFetchTasks: {
                continuationReady = true
                await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                    continuation = cont
                }
            }
        )

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        // Start the fetch in a Task
        let fetchTask = Task {
            await store.fetchMyTasks()
        }

        // Wait briefly for the continuation to be set up
        var attempts = 0
        while !continuationReady && attempts < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            attempts += 1
        }

        // Immediately assert loading state is true (fetch is in progress)
        #expect(store.isLoading == true)

        // Resume the continuation to let the mock complete
        continuation?.resume()

        // Wait for fetch to complete
        await fetchTask.value

        // Assert loading state is false after completion
        #expect(store.isLoading == false)
    }

    @Test("Fetch clears error message on success")
    func fetchClearsError() async {
        let mockTasks: [TaskWithMessages] = [.mock(status: .claimed, assignedStaffId: "user-123")]
        let repo = TaskRepositoryClient.mock(tasks: mockTasks)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        store.errorMessage = "Previous error"

        await store.fetchMyTasks()

        #expect(store.errorMessage == nil)
    }
}

// MARK: - Error Handling Tests

@Suite("MyTasksStore - Error Handling", .serialized)
@MainActor
struct MyTasksStoreErrorTests {

    @Test("Fetch handles repository error")
    func fetchRepositoryError() async {
        let repo = TaskRepositoryClient.mock(shouldThrow: true)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        #expect(store.errorMessage != nil)
        #expect(store.errorMessage?.contains("Failed to load tasks") == true)
        #expect(store.isLoading == false)
    }

    @Test("Fetch handles auth client error")
    func fetchAuthError() async {
        let repo = TaskRepositoryClient.mock()

        let store = withDependencies {
            $0.authClient.currentUserId = { throw TestError.authFailed }
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        #expect(store.errorMessage != nil)
        #expect(store.isLoading == false)
    }

    @Test("Claim task handles error")
    func claimTaskError() async {
        let repo = TaskRepositoryClient.mock(shouldThrow: true)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        let task = AgentTask.mock(id: "task-1")
        await store.claimTask(task)

        #expect(store.errorMessage != nil)
        #expect(store.errorMessage?.contains("Failed to claim task") == true)
    }

    @Test("Delete task handles error")
    func deleteTaskError() async {
        let repo = TaskRepositoryClient.mock(shouldThrow: true)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        let task = AgentTask.mock(id: "task-1")
        await store.deleteTask(task)

        #expect(store.errorMessage != nil)
        #expect(store.errorMessage?.contains("Failed to delete task") == true)
    }
}

// MARK: - Action Tests

@Suite("MyTasksStore - Actions", .serialized)
@MainActor
struct MyTasksStoreActionTests {

    @Test("Claim task calls repository and refreshes")
    func claimTask() async {
        let mockTasks: [TaskWithMessages] = [.mock(id: "task-1", status: .claimed, assignedStaffId: "user-123")]
        var claimedTaskId: String?

        let repo = TaskRepositoryClient.mock(
            tasks: mockTasks,
            onClaimTask: { taskId in
                claimedTaskId = taskId
            }
        )

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        let task = AgentTask.mock(id: "task-1")
        await store.claimTask(task)

        #expect(claimedTaskId == "task-1")
        #expect(store.errorMessage == nil)
    }

    @Test("Delete task calls repository and refreshes")
    func deleteTask() async {
        var deletedTaskId: String?

        let repo = TaskRepositoryClient.mock(
            onDeleteTask: { taskId in
                deletedTaskId = taskId
            }
        )

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        let task = AgentTask.mock(id: "task-1")
        await store.deleteTask(task)

        #expect(deletedTaskId == "task-1")
        #expect(store.errorMessage == nil)
    }
}

// MARK: - Expansion State Tests

@Suite("MyTasksStore - Expansion State", .serialized)
@MainActor
struct MyTasksStoreExpansionTests {

    @Test("Toggle expansion sets task as expanded")
    func toggleExpansionSets() {
        let repo = TaskRepositoryClient.mock()
        let store = MyTasksStore(repository: repo)

        store.toggleExpansion(for: "task-1")

        #expect(store.expandedTaskId == "task-1")
    }

    @Test("Toggle expansion clears when called on same task")
    func toggleExpansionClears() {
        let repo = TaskRepositoryClient.mock()
        let store = MyTasksStore(repository: repo)

        store.toggleExpansion(for: "task-1")
        store.toggleExpansion(for: "task-1")

        #expect(store.expandedTaskId == nil)
    }

    @Test("Toggle expansion switches between tasks")
    func toggleExpansionSwitches() {
        let repo = TaskRepositoryClient.mock()
        let store = MyTasksStore(repository: repo)

        store.toggleExpansion(for: "task-1")
        #expect(store.expandedTaskId == "task-1")

        store.toggleExpansion(for: "task-2")
        #expect(store.expandedTaskId == "task-2")
    }
}

// MARK: - User Filtering Tests

@Suite("MyTasksStore - User Filtering Logic", .serialized)
@MainActor
struct MyTasksStoreFilteringTests {

    @Test("Empty repository returns empty tasks")
    func emptyRepository() async {
        let repo = TaskRepositoryClient.mock(tasks: [])

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        #expect(store.tasks.isEmpty)
    }

    @Test("Different user ID filters correctly")
    func differentUserId() async {
        let mockTasks: [TaskWithMessages] = [
            .mock(id: "task-1", status: .claimed, assignedStaffId: "user-456"),
            .mock(id: "task-2", status: .inProgress, assignedStaffId: "user-789")
        ]
        let repo = TaskRepositoryClient.mock(tasks: mockTasks)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" } // Returns user-123
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        // Should be empty since no tasks belong to user-123
        #expect(store.tasks.isEmpty)
    }

    @Test("Mixed statuses filter correctly")
    func mixedStatuses() async {
        let mockTasks: [TaskWithMessages] = [
            .mock(id: "task-1", status: .claimed, assignedStaffId: "user-123"),
            .mock(id: "task-2", status: .inProgress, assignedStaffId: "user-123"),
            .mock(id: "task-3", status: .done, assignedStaffId: "user-123"),
            .mock(id: "task-4", status: .open, assignedStaffId: "user-123"),
            .mock(id: "task-5", status: .cancelled, assignedStaffId: "user-123")
        ]
        let repo = TaskRepositoryClient.mock(tasks: mockTasks)

        let store = withDependencies {
            $0.authClient.currentUserId = { "user-123" }
        } operation: {
            MyTasksStore(repository: repo)
        }

        await store.fetchMyTasks()

        #expect(store.tasks.count == 2)
        let taskIds = Set(store.tasks.map { $0.id })
        #expect(taskIds.contains("task-1"))
        #expect(taskIds.contains("task-2"))
    }
}
