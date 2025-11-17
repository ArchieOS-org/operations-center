//
//  TaskRepositoryTests.swift
//  Operations Center Tests
//
//  Tests for TaskRepository CRUD operations
//  Uses MockTaskRepository with real business logic
//
//  NOTE: These tests use MockTaskRepository directly and don't require
//  Supabase or network access. They verify core business logic in isolation.
//

import Testing
import Foundation
import OperationsCenterKit

/// Tests for TaskRepository operations
@Suite("Task Repository Tests")
@MainActor
struct TaskRepositoryTests {

    // MARK: - Fetch Tests

    @Test("Fetch tasks returns non-deleted tasks")
    func testFetchTasks() async throws {
        let repository = MockTaskRepository()

        let tasks = try await repository.fetchTasks()

        #expect(tasks.count > 0)
        #expect(tasks.allSatisfy { $0.task.deletedAt == nil })
    }

    @Test("Fetch activities returns non-deleted activities")
    func testFetchActivities() async throws {
        let repository = MockTaskRepository()

        let activities = try await repository.fetchActivities()

        #expect(activities.count > 0)
        #expect(activities.allSatisfy { $0.task.deletedAt == nil })
    }

    @Test("Fetch activities includes listing details")
    func testFetchActivitiesIncludesListings() async throws {
        let repository = MockTaskRepository()

        let activities = try await repository.fetchActivities()

        #expect(activities.count > 0)
        for activity in activities {
            #expect(activity.listing.id == activity.task.listingId)
        }
    }

    // MARK: - Claim Tests

    @Test("Claim task updates status and timestamps")
    func testClaimTask() async throws {
        let repository = MockTaskRepository()
        let staffId = "staff-123"

        // Get initial tasks
        let initialTasks = try await repository.fetchTasks()
        guard let firstTask = initialTasks.first else {
            Issue.record("No tasks available for claiming")
            return
        }

        // Claim the task
        let claimed = try await repository.claimTask(taskId: firstTask.task.id, staffId: staffId)

        // Verify state changes
        #expect(claimed.status == .claimed)
        #expect(claimed.assignedStaffId == staffId)
        #expect(claimed.claimedAt != nil)
        #expect(claimed.id == firstTask.task.id)
    }

    @Test("Claim activity updates status and timestamps")
    func testClaimActivity() async throws {
        let repository = MockTaskRepository()
        let staffId = "staff-123"

        // Get initial activities
        let initialActivities = try await repository.fetchActivities()
        guard let firstActivity = initialActivities.first else {
            Issue.record("No activities available for claiming")
            return
        }

        // Claim the activity
        let claimed = try await repository.claimActivity(taskId: firstActivity.task.id, staffId: staffId)

        // Verify state changes
        #expect(claimed.status == .claimed)
        #expect(claimed.assignedStaffId == staffId)
        #expect(claimed.claimedAt != nil)
        #expect(claimed.id == firstActivity.task.id)
    }

    @Test("Claim non-existent task throws error")
    func testClaimNonExistentTask() async throws {
        let repository = MockTaskRepository()
        let fakeTaskId = "non-existent-task"

        // Should throw MockRepositoryError.taskNotFound
        await #expect(throws: MockRepositoryError.taskNotFound) {
            try await repository.claimTask(taskId: fakeTaskId, staffId: "staff-123")
        }
    }

    // MARK: - Delete Tests

    @Test("Delete task performs soft delete")
    func testDeleteTask() async throws {
        let repository = MockTaskRepository()
        let deletedBy = "admin-456"

        // Get initial tasks
        let initialTasks = try await repository.fetchTasks()
        let initialCount = initialTasks.count
        guard let firstTask = initialTasks.first else {
            Issue.record("No tasks available for deletion")
            return
        }

        // Delete the task
        try await repository.deleteTask(taskId: firstTask.task.id, deletedBy: deletedBy)

        // Verify soft delete (task should NOT appear in fetch)
        let remainingTasks = try await repository.fetchTasks()
        #expect(remainingTasks.count == initialCount - 1)
        #expect(remainingTasks.allSatisfy { $0.task.id != firstTask.task.id })
    }

    @Test("Delete activity performs soft delete")
    func testDeleteActivity() async throws {
        let repository = MockTaskRepository()
        let deletedBy = "admin-456"

        // Get initial activities
        let initialActivities = try await repository.fetchActivities()
        let initialCount = initialActivities.count
        guard let firstActivity = initialActivities.first else {
            Issue.record("No activities available for deletion")
            return
        }

        // Delete the activity
        try await repository.deleteActivity(taskId: firstActivity.task.id, deletedBy: deletedBy)

        // Verify soft delete (activity should NOT appear in fetch)
        let remainingActivities = try await repository.fetchActivities()
        #expect(remainingActivities.count == initialCount - 1)
        #expect(remainingActivities.allSatisfy { $0.task.id != firstActivity.task.id })
    }

    @Test("Delete non-existent task throws error")
    func testDeleteNonExistentTask() async throws {
        let repository = MockTaskRepository()
        let fakeTaskId = "non-existent-task"

        // Should throw MockRepositoryError.taskNotFound
        await #expect(throws: MockRepositoryError.taskNotFound) {
            try await repository.deleteTask(taskId: fakeTaskId, deletedBy: "admin-456")
        }
    }

    // MARK: - Slack Messages Tests

    @Test("Fetch tasks includes associated Slack messages")
    func testFetchTasksIncludesMessages() async throws {
        let repository = MockTaskRepository()

        let tasks = try await repository.fetchTasks()

        // At least one task should have messages (per TaskMockData)
        let tasksWithMessages = tasks.filter { !$0.messages.isEmpty }
        #expect(tasksWithMessages.count > 0)
    }

    // MARK: - State Isolation Tests

    @Test("Multiple repository instances have independent state")
    func testRepositoryIsolation() async throws {
        let repo1 = MockTaskRepository()
        let repo2 = MockTaskRepository()

        // Get initial counts
        let tasks1 = try await repo1.fetchTasks()
        let tasks2 = try await repo2.fetchTasks()
        #expect(tasks1.count == tasks2.count)

        // Delete from repo1
        if let firstTask = tasks1.first {
            try await repo1.deleteTask(taskId: firstTask.task.id, deletedBy: "test")
        }

        // Verify repo1 changed but repo2 didn't
        let tasks1After = try await repo1.fetchTasks()
        let tasks2After = try await repo2.fetchTasks()
        #expect(tasks1After.count == tasks1.count - 1)
        #expect(tasks2After.count == tasks2.count) // Unchanged
    }

    // MARK: - MainActor Serialization Tests

    @Test("MainActor serializes concurrent task submissions")
    func testMainActorSerializedOperations() async throws {
        let repository = MockTaskRepository()

        // Submit multiple operations concurrently - @MainActor ensures serial execution
        var fetchCount = 0
        var claimSucceeded = false

        await withTaskGroup(of: Void.self) { group in
            // Task 1: Fetch tasks
            group.addTask {
                do {
                    let tasks = try await repository.fetchTasks()
                    fetchCount = tasks.count
                } catch {
                    // Fail test if operation throws
                    fatalError("Fetch tasks failed: \(error)")
                }
            }

            // Task 2: Fetch activities
            group.addTask {
                do {
                    _ = try await repository.fetchActivities()
                } catch {
                    fatalError("Fetch activities failed: \(error)")
                }
            }

            // Task 3: Claim a task
            group.addTask {
                do {
                    let tasks = try await repository.fetchTasks()
                    if let task = tasks.first {
                        let result = try await repository.claimTask(taskId: task.task.id, staffId: "staff-concurrent")
                        claimSucceeded = (result.assignedStaffId == "staff-concurrent")
                    }
                } catch {
                    fatalError("Claim task failed: \(error)")
                }
            }
        }

        // Verify all operations completed successfully
        #expect(fetchCount > 0)
        #expect(claimSucceeded)

        // Verify repository state is consistent after serialized operations
        let tasks = try await repository.fetchTasks()
        #expect(tasks.count > 0)
        #expect(tasks.contains(where: { $0.task.assignedStaffId == "staff-concurrent" }))
    }
}
