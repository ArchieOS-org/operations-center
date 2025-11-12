//
//  MockTaskRepository.swift
//  OperationsCenterKit
//
//  Mock implementation of TaskRepository for development and testing
//  Thread-safe actor with realistic delays to simulate network latency
//

import Foundation

/// Thread-safe mock repository with simulated network delays
@MainActor
public final class MockTaskRepository: TaskRepository, @unchecked Sendable {
    // MARK: - State

    private var strayTasks: [StrayTask]
    private var listingTasks: [ListingTask]
    private var slackMessages: [String: [SlackMessage]] // taskId -> messages
    private var subtasks: [String: [Subtask]] // taskId -> subtasks

    // MARK: - Configuration

    /// Simulated network delay (default: 200ms)
    public var networkDelay: Duration = .milliseconds(200)

    // MARK: - Initialization

    public init() {
        // Initialize with mock data
        let mockData = TaskMockData()
        self.strayTasks = mockData.strayTasks
        self.listingTasks = mockData.listingTasks
        self.slackMessages = mockData.slackMessages
        self.subtasks = mockData.subtasks
    }

    /// Factory method for creating instances from non-isolated contexts
    public nonisolated static func create() -> MockTaskRepository {
        // This is safe because we're creating a new instance
        // that will be immediately passed to a @MainActor context
        MainActor.assumeIsolated {
            MockTaskRepository()
        }
    }

    // MARK: - TaskRepository Implementation

    public func fetchStrayTasks() async throws -> [(task: StrayTask, messages: [SlackMessage])] {
        return strayTasks
            .filter { $0.deletedAt == nil }
            .map { task in
                let messages = slackMessages[task.id] ?? []
                return (task: task, messages: messages)
            }
    }

    public func fetchListingTasks() async throws -> [(task: ListingTask, subtasks: [Subtask])] {
        return listingTasks
            .filter { $0.deletedAt == nil }
            .map { task in
                let taskSubtasks = subtasks[task.id] ?? []
                return (task: task, subtasks: taskSubtasks)
            }
    }

    public func claimStrayTask(taskId: String, staffId: String) async throws -> StrayTask {
        guard let index = strayTasks.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Create updated task
        let original = strayTasks[index]
        let updated = StrayTask(
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

        strayTasks[index] = updated
        return updated
    }

    public func claimListingTask(taskId: String, staffId: String) async throws -> ListingTask {
        guard let index = listingTasks.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Create updated task
        let original = listingTasks[index]
        let updated = ListingTask(
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

        listingTasks[index] = updated
        return updated
    }

    public func deleteStrayTask(taskId: String, deletedBy: String) async throws {
        guard let index = strayTasks.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Soft delete
        let original = strayTasks[index]
        let updated = StrayTask(
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

        strayTasks[index] = updated
    }

    public func deleteListingTask(taskId: String, deletedBy: String) async throws {
        guard let index = listingTasks.firstIndex(where: { $0.id == taskId }) else {
            throw MockRepositoryError.taskNotFound
        }

        // Soft delete
        let original = listingTasks[index]
        let updated = ListingTask(
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

        listingTasks[index] = updated
    }

    public func completeSubtask(subtaskId: String) async throws -> Subtask {
        // Find subtask across all task subtask arrays
        for (taskId, var taskSubtasks) in subtasks {
            if let index = taskSubtasks.firstIndex(where: { $0.id == subtaskId }) {
                let original = taskSubtasks[index]
                let updated = Subtask(
                    id: original.id,
                    parentTaskId: original.parentTaskId,
                    name: original.name,
                    isCompleted: true,
                    completedAt: Date(),
                    createdAt: original.createdAt
                )
                taskSubtasks[index] = updated
                subtasks[taskId] = taskSubtasks
                return updated
            }
        }

        throw MockRepositoryError.subtaskNotFound
    }

    public func uncompleteSubtask(subtaskId: String) async throws -> Subtask {
        // Find subtask across all task subtask arrays
        for (taskId, var taskSubtasks) in subtasks {
            if let index = taskSubtasks.firstIndex(where: { $0.id == subtaskId }) {
                let original = taskSubtasks[index]
                let updated = Subtask(
                    id: original.id,
                    parentTaskId: original.parentTaskId,
                    name: original.name,
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: original.createdAt
                )
                taskSubtasks[index] = updated
                subtasks[taskId] = taskSubtasks
                return updated
            }
        }

        throw MockRepositoryError.subtaskNotFound
    }
}

// MARK: - Errors

public enum MockRepositoryError: LocalizedError {
    case taskNotFound
    case subtaskNotFound

    public var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "Task not found"
        case .subtaskNotFound:
            return "Subtask not found"
        }
    }
}
