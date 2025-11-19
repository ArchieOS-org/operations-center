//
//  MockTaskRepository.swift
//  Operations Center Tests
//
//  Mock implementation of TaskRepository for development and testing
//

import Foundation
import OperationsCenterKit

/// Thread-safe mock repository
@MainActor
final class MockTaskRepository: TaskRepository, @unchecked Sendable {
    // MARK: - State

    private var tasks: [AgentTask]
    private var activities: [Activity]
    private var listings: [String: Listing] // listingId -> Listing
    private var slackMessages: [String: [SlackMessage]] // taskId -> messages

    // MARK: - Initialization

    init() {
        // Initialize with mock data
        let mockData = TaskMockData()
        self.tasks = mockData.tasks
        self.activities = mockData.activities
        self.listings = mockData.listings
        self.slackMessages = mockData.slackMessages
    }

    /// Factory method for creating instances from non-isolated contexts
    nonisolated static func create() -> MockTaskRepository {
        // This is safe because we're creating a new instance
        // that will be immediately passed to a @MainActor context
        MainActor.assumeIsolated {
            MockTaskRepository()
        }
    }

    // MARK: - TaskRepository Implementation

    func fetchTasks() async throws -> [TaskWithMessages] {
        return tasks
            .filter { $0.deletedAt == nil }
            .map { task in
                let messages = slackMessages[task.id] ?? []
                return TaskWithMessages(task: task, messages: messages)
            }
    }

    func fetchActivities() async throws -> [ActivityWithDetails] {
        return activities
            .filter { $0.deletedAt == nil }
            .compactMap { task in
                guard let listing = listings[task.listingId] else {
                    return nil
                }
                return ActivityWithDetails(task: task, listing: listing)
            }
    }

    func claimTask(taskId: String, staffId: String) async throws -> AgentTask {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Create updated task
        let original = tasks[index]
        let updated = AgentTask(
            id: original.id,
            realtorId: original.realtorId,
            name: original.name,
            description: original.description,
            taskCategory: original.taskCategory,
            status: .claimed,
            priority: original.priority,
            assignedStaffId: staffId,
            dueDate: original.dueDate,
            claimedAt: Date(),
            completedAt: original.completedAt,
            createdAt: original.createdAt,
            updatedAt: Date(),
            deletedAt: original.deletedAt,
            deletedBy: original.deletedBy
        )

        tasks[index] = updated
        return updated
    }

    func claimActivity(taskId: String, staffId: String) async throws -> Activity {
        guard let index = activities.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Create updated task
        let original = activities[index]
        let updated = Activity(
            id: original.id,
            listingId: original.listingId,
            realtorId: original.realtorId,
            name: original.name,
            description: original.description,
            taskCategory: original.taskCategory,
            status: .claimed,
            priority: original.priority,
            visibilityGroup: original.visibilityGroup,
            assignedStaffId: staffId,
            dueDate: original.dueDate,
            claimedAt: Date(),
            completedAt: original.completedAt,
            createdAt: original.createdAt,
            updatedAt: Date(),
            deletedAt: original.deletedAt,
            deletedBy: original.deletedBy,
            inputs: original.inputs,
            outputs: original.outputs
        )

        activities[index] = updated
        return updated
    }

    func deleteTask(taskId: String, deletedBy: String) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Soft delete
        let original = tasks[index]
        let updated = AgentTask(
            id: original.id,
            realtorId: original.realtorId,
            name: original.name,
            description: original.description,
            taskCategory: original.taskCategory,
            status: original.status,
            priority: original.priority,
            assignedStaffId: original.assignedStaffId,
            dueDate: original.dueDate,
            claimedAt: original.claimedAt,
            completedAt: original.completedAt,
            createdAt: original.createdAt,
            updatedAt: Date(),
            deletedAt: Date(),
            deletedBy: deletedBy
        )

        tasks[index] = updated
    }

    func deleteActivity(taskId: String, deletedBy: String) async throws {
        guard let index = activities.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Soft delete
        let original = activities[index]
        let updated = Activity(
            id: original.id,
            listingId: original.listingId,
            realtorId: original.realtorId,
            name: original.name,
            description: original.description,
            taskCategory: original.taskCategory,
            status: original.status,
            priority: original.priority,
            visibilityGroup: original.visibilityGroup,
            assignedStaffId: original.assignedStaffId,
            dueDate: original.dueDate,
            claimedAt: original.claimedAt,
            completedAt: original.completedAt,
            createdAt: original.createdAt,
            updatedAt: Date(),
            deletedAt: Date(),
            deletedBy: deletedBy,
            inputs: original.inputs,
            outputs: original.outputs
        )

        activities[index] = updated
    }
}

// MARK: - Errors

enum MockRepositoryError: LocalizedError {
    case taskNotFound

    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "Task not found"
        }
    }
}
