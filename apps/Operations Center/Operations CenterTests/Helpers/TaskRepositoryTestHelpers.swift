//
//  TaskRepositoryTestHelpers.swift
//  Operations Center Tests
//
//  Shared test utilities for TaskRepositoryClient mocking
//  Following PointFree pattern: static .mock, .testValue, .unimplemented
//

import Foundation
import OperationsCenterKit
@testable import Operations_Center

// MARK: - TaskRepositoryClient Test Helpers

extension TaskRepositoryClient {
    /// Unimplemented repository - fails fast if any method is called
    /// Use when testing code that shouldn't touch the repository
    static var unimplemented: Self {
        Self(
            fetchTasks: { fatalError("TaskRepositoryClient.fetchTasks is unimplemented") },
            fetchActivities: { fatalError("TaskRepositoryClient.fetchActivities is unimplemented") },
            fetchDeletedTasks: { fatalError("TaskRepositoryClient.fetchDeletedTasks is unimplemented") },
            fetchDeletedActivities: { fatalError("TaskRepositoryClient.fetchDeletedActivities is unimplemented") },
            claimTask: { _, _ in fatalError("TaskRepositoryClient.claimTask is unimplemented") },
            claimActivity: { _, _ in fatalError("TaskRepositoryClient.claimActivity is unimplemented") },
            deleteTask: { _, _ in fatalError("TaskRepositoryClient.deleteTask is unimplemented") },
            deleteActivity: { _, _ in fatalError("TaskRepositoryClient.deleteActivity is unimplemented") },
            fetchTasksByRealtor: { _ in fatalError("TaskRepositoryClient.fetchTasksByRealtor is unimplemented") },
            fetchActivitiesByRealtor: { _ in fatalError("TaskRepositoryClient.fetchActivitiesByRealtor is unimplemented") },
            fetchCompletedTasks: { fatalError("TaskRepositoryClient.fetchCompletedTasks is unimplemented") },
            fetchActivitiesByStaff: { _ in fatalError("TaskRepositoryClient.fetchActivitiesByStaff is unimplemented") }
        )
    }

    /// Configurable mock repository for testing
    /// All closures default to empty/no-op implementations
    static func mock(
        tasks: [TaskWithMessages] = [],
        activities: [ActivityWithDetails] = [],
        deletedTasks: [AgentTask] = [],
        deletedActivities: [ActivityWithDetails] = [],
        shouldThrow: Bool = false,
        onFetchTasks: (@Sendable () async -> Void)? = nil,
        onClaimTask: @escaping (String) -> Void = { _ in },
        onClaimActivity: @escaping (String) -> Void = { _ in },
        onDeleteTask: @escaping (String) -> Void = { _ in },
        onDeleteActivity: @escaping (String) -> Void = { _ in }
    ) -> Self {
        Self(
            fetchTasks: {
                if let onFetch = onFetchTasks {
                    await onFetch()
                }
                if shouldThrow { throw TestError.mockFailure }
                return tasks
            },
            fetchActivities: {
                if shouldThrow { throw TestError.mockFailure }
                return activities
            },
            fetchDeletedTasks: {
                if shouldThrow { throw TestError.mockFailure }
                return deletedTasks
            },
            fetchDeletedActivities: {
                if shouldThrow { throw TestError.mockFailure }
                return deletedActivities
            },
            claimTask: { taskId, staffId in
                if shouldThrow { throw TestError.mockFailure }
                onClaimTask(taskId)
                return AgentTask(
                    id: taskId,
                    realtorId: "test-realtor",
                    name: "Claimed Task",
                    status: .claimed,
                    priority: 50,
                    assignedStaffId: staffId,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            },
            claimActivity: { taskId, staffId in
                if shouldThrow { throw TestError.mockFailure }
                onClaimActivity(taskId)
                return Activity(
                    id: taskId,
                    listingId: "test-listing",
                    realtorId: "test-realtor",
                    name: "Claimed Activity",
                    description: nil,
                    taskCategory: nil,
                    status: .claimed,
                    priority: 50,
                    visibilityGroup: .both,
                    assignedStaffId: staffId,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            },
            deleteTask: { taskId, _ in
                if shouldThrow { throw TestError.mockFailure }
                onDeleteTask(taskId)
            },
            deleteActivity: { taskId, _ in
                if shouldThrow { throw TestError.mockFailure }
                onDeleteActivity(taskId)
            },
            fetchTasksByRealtor: { _ in
                if shouldThrow { throw TestError.mockFailure }
                return tasks
            },
            fetchActivitiesByRealtor: { _ in
                if shouldThrow { throw TestError.mockFailure }
                return activities
            },
            fetchCompletedTasks: {
                if shouldThrow { throw TestError.mockFailure }
                return deletedTasks.filter { $0.status == .done }
            },
            fetchActivitiesByStaff: { _ in
                if shouldThrow { throw TestError.mockFailure }
                return activities
            }
        )
    }
}

// MARK: - Mock Data Helpers

extension AgentTask {
    /// Create mock AgentTask for testing
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
    ) -> AgentTask {
        AgentTask(
            id: id,
            realtorId: realtorId,
            name: name,
            description: description,
            taskCategory: taskCategory,
            status: status,
            priority: priority,
            assignedStaffId: assignedStaffId,
            dueDate: dueDate,
            claimedAt: claimedAt,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            deletedBy: deletedBy
        )
    }
}

extension TaskWithMessages {
    /// Create mock TaskWithMessages for testing
    static func mock(
        id: String = UUID().uuidString,
        status: TaskStatus = .open,
        assignedStaffId: String? = nil,
        messages: [SlackMessage] = []
    ) -> TaskWithMessages {
        let task = AgentTask.mock(
            id: id,
            status: status,
            assignedStaffId: assignedStaffId
        )
        return TaskWithMessages(task: task, messages: messages)
    }
}

extension Activity {
    /// Create mock Activity for testing
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
    ) -> Activity {
        Activity(
            id: id,
            listingId: listingId,
            realtorId: realtorId,
            name: name,
            description: description,
            taskCategory: taskCategory,
            status: status,
            priority: priority,
            visibilityGroup: visibilityGroup,
            assignedStaffId: assignedStaffId,
            dueDate: dueDate,
            claimedAt: claimedAt,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            deletedBy: deletedBy,
            inputs: nil,
            outputs: nil
        )
    }
}

extension ActivityWithDetails {
    /// Create mock ActivityWithDetails for testing
    static func mock(
        id: String = UUID().uuidString,
        listingId: String = "test-listing",
        status: TaskStatus = .open,
        assignedStaffId: String? = nil,
        listing: Listing? = nil
    ) -> ActivityWithDetails {
        let activity = Activity.mock(
            id: id,
            listingId: listingId,
            status: status,
            assignedStaffId: assignedStaffId
        )
        let mockListing = listing ?? Listing.mock(id: listingId)
        return ActivityWithDetails(task: activity, listing: mockListing)
    }
}

extension Listing {
    /// Create mock Listing for testing
    static func mock(
        id: String = UUID().uuidString,
        addressString: String = "123 Test St, Test City, CA 12345",
        status: String = "active",
        assignee: String? = nil,
        realtorId: String? = "test-realtor",
        dueDate: Date? = nil,
        progress: Decimal? = nil,
        type: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        deletedAt: Date? = nil
    ) -> Listing {
        Listing(
            id: id,
            addressString: addressString,
            status: status,
            assignee: assignee,
            realtorId: realtorId,
            dueDate: dueDate,
            progress: progress,
            type: type,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            deletedAt: deletedAt
        )
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case mockFailure
    case authFailed
}

// MARK: - AuthClient Test Helpers

extension AuthClient {
    /// Mock auth client with configurable user ID
    /// Usage: `$0.authClient = .mock(userId: "user-123")`
    static func mock(userId: String = "test-user-id") -> Self {
        Self(currentUserId: { userId })
    }

    /// Mock auth client that throws an error
    /// Usage: `$0.authClient = .mockFailure`
    static var mockFailure: Self {
        Self(currentUserId: { throw TestError.authFailed })
    }
}
