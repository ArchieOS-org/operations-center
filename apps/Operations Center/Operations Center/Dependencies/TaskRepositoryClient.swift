//
//  TaskRepositoryClient.swift
//  Operations Center
//
//  Task repository client using native Swift patterns
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

// MARK: - Task Repository Client

/// Task repository client for production and preview contexts
public struct TaskRepositoryClient {
    /// Fetch all tasks with their associated Slack messages
    public var fetchTasks: @Sendable () async throws -> [TaskWithMessages]

    /// Fetch all activities with their listing data and subtasks
    public var fetchActivities: @Sendable () async throws -> [ActivityWithDetails]

    /// Claim a task
    public var claimTask: @Sendable (_ taskId: String, _ staffId: String) async throws -> AgentTask

    /// Claim an activity
    public var claimActivity: @Sendable (_ taskId: String, _ staffId: String) async throws -> Activity

    /// Delete a task (soft delete)
    public var deleteTask: @Sendable (_ taskId: String, _ deletedBy: String) async throws -> Void

    /// Delete an activity (soft delete)
    public var deleteActivity: @Sendable (_ taskId: String, _ deletedBy: String) async throws -> Void

    /// Complete a subtask within an activity
    public var completeSubtask: @Sendable (_ subtaskId: String) async throws -> Subtask

    /// Uncomplete a subtask within an activity
    public var uncompleteSubtask: @Sendable (_ subtaskId: String) async throws -> Subtask

    /// Fetch tasks for a specific realtor
    public var fetchTasksByRealtor: @Sendable (_ realtorId: String) async throws -> [TaskWithMessages]

    /// Fetch activities for a specific realtor
    public var fetchActivitiesByRealtor: @Sendable (_ realtorId: String) async throws -> [ActivityWithDetails]

    /// Fetch completed tasks (for Logbook)
    public var fetchCompletedTasks: @Sendable () async throws -> [AgentTask]
}

// MARK: - Response Models

/// Decodable response model for activities with nested listings join
private struct ActivityResponse: Decodable {
    let taskId: String
    let listingId: String
    let realtorId: String?
    let name: String
    let description: String?
    let taskCategory: String
    let status: String
    let priority: Int
    let visibilityGroup: String
    let assignedStaffId: String?
    let dueDate: Date?
    let claimedAt: Date?
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let deletedBy: String?
    let inputs: [String: AnyCodable]?
    let outputs: [String: AnyCodable]?
    let listing: Listing?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case listingId = "listing_id"
        case realtorId = "realtor_id"
        case name
        case description
        case taskCategory = "task_category"
        case status
        case priority
        case visibilityGroup = "visibility_group"
        case assignedStaffId = "assigned_staff_id"
        case dueDate = "due_date"
        case claimedAt = "claimed_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case deletedBy = "deleted_by"
        case inputs
        case outputs
        case listing = "listings"
    }
}

// MARK: - Helper Functions

/// Map an ActivityResponse to ActivityWithDetails
/// Shared by fetchActivities and fetchActivitiesByRealtor
nonisolated private func mapActivityResponse(_ row: ActivityResponse) -> ActivityWithDetails? {
    guard let listing = row.listing else {
        // Logging removed to avoid introducing MainActor isolation in this pure mapping function
        return nil
    }

    let task = Activity(
        id: row.taskId,
        listingId: row.listingId,
        realtorId: row.realtorId,
        name: row.name,
        description: row.description,
        taskCategory: Activity.TaskCategory(rawValue: row.taskCategory) ?? .other,
        status: Activity.TaskStatus(rawValue: row.status) ?? .open,
        priority: row.priority,
        visibilityGroup: Activity.VisibilityGroup(rawValue: row.visibilityGroup) ?? .both,
        assignedStaffId: row.assignedStaffId,
        dueDate: row.dueDate,
        claimedAt: row.claimedAt,
        completedAt: row.completedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        deletedBy: row.deletedBy,
        inputs: row.inputs,
        outputs: row.outputs
    )

    // swiftlint:disable:next todo
    // TODO: Add subtasks query once subtasks table exists
    let subtasks: [Subtask] = []

    return ActivityWithDetails(task: task, listing: listing, subtasks: subtasks)
}

// MARK: - Live Implementation

extension TaskRepositoryClient {
    /// Production implementation using global Supabase client
    public static let live = Self(
            fetchTasks: {
                let response: [AgentTask] = try await supabase
                    .from("agent_tasks")
                    .select()
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                // Return tasks with empty messages - nested queries need better handling
                return response.map { TaskWithMessages(task: $0, messages: []) }
            },
            fetchActivities: {
                // Query activities with nested listings join
                let response: [ActivityResponse] = try await supabase
                    .from("activities")
                    .select("*, listings(*)")
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return response.compactMap(mapActivityResponse)
            },
            claimTask: { taskId, staffId in
                let now = Date()

                let response: AgentTask = try await supabase
                    .from("agent_tasks")
                    .update([
                        "assigned_staff_id": staffId,
                        "claimed_at": now.ISO8601Format(),
                        "status": AgentTask.TaskStatus.claimed.rawValue
                    ])
                    .eq("task_id", value: taskId)
                    .select()
                    .single()
                    .execute()
                    .value

                return response
            },
            claimActivity: { taskId, staffId in
                let now = Date()

                let response: Activity = try await supabase
                    .from("activities")
                    .update([
                        "assigned_staff_id": staffId,
                        "claimed_at": now.ISO8601Format(),
                        "status": Activity.TaskStatus.claimed.rawValue
                    ])
                    .eq("task_id", value: taskId)
                    .select()
                    .single()
                    .execute()
                    .value

                return response
            },
            deleteTask: { taskId, deletedBy in
                let now = Date()

                try await supabase
                    .from("agent_tasks")
                    .update([
                        "deleted_at": now.ISO8601Format(),
                        "deleted_by": deletedBy
                    ])
                    .eq("task_id", value: taskId)
                    .execute()
            },
            deleteActivity: { taskId, deletedBy in
                let now = Date()

                try await supabase
                    .from("activities")
                    .update([
                        "deleted_at": now.ISO8601Format(),
                        "deleted_by": deletedBy
                    ])
                    .eq("task_id", value: taskId)
                    .execute()
            },
            completeSubtask: { _ in
                // swiftlint:disable:next todo
                // TODO: Implement once subtasks table exists
                throw NSError(domain: "TaskRepositoryClient", code: 501, userInfo: [
                    NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
                ])
            },
            uncompleteSubtask: { _ in
                // swiftlint:disable:next todo
                // TODO: Implement once subtasks table exists
                throw NSError(domain: "TaskRepositoryClient", code: 501, userInfo: [
                    NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
                ])
            },
            fetchTasksByRealtor: { realtorId in
                let response: [AgentTask] = try await supabase
                    .from("agent_tasks")
                    .select()
                    .eq("realtor_id", value: realtorId)
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                // Return tasks with empty messages - nested queries need better handling
                return response.map { TaskWithMessages(task: $0, messages: []) }
            },
            fetchActivitiesByRealtor: { realtorId in
                // Query activities with nested listings join
                let response: [ActivityResponse] = try await supabase
                    .from("activities")
                    .select("*, listings(*)")
                    .eq("realtor_id", value: realtorId)
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return response.compactMap(mapActivityResponse)
            },
            fetchCompletedTasks: {
                Logger.database.info("Fetching completed tasks")
                let tasks: [AgentTask] = try await supabase
                    .from("agent_tasks")
                    .select()
                    .eq("status", value: AgentTask.TaskStatus.done.rawValue)
                    .is("deleted_at", value: nil)
                    .order("completed_at", ascending: false)
                    .execute()
                    .value

                Logger.database.info("Fetched \(tasks.count) completed agent tasks")
                return tasks
            }
        )
    }

// MARK: - Preview Implementation

extension TaskRepositoryClient {
    /// Preview implementation with mock data for Xcode previews
    public static let preview = Self(
        fetchTasks: {
            [
                TaskWithMessages(task: AgentTask.mock1, messages: [SlackMessage.mock1]),
                TaskWithMessages(task: AgentTask.mock2, messages: []),
                TaskWithMessages(task: AgentTask.mock3, messages: [SlackMessage.mock2])
            ]
        },
        fetchActivities: {
            [
                ActivityWithDetails(
                    task: Activity.mock1,
                    listing: Listing.mock1,
                    subtasks: [Subtask.mock1, Subtask.mock2]
                ),
                ActivityWithDetails(
                    task: Activity.mock2,
                    listing: Listing.mock2,
                    subtasks: []
                ),
                ActivityWithDetails(
                    task: Activity.mock3,
                    listing: Listing.mock3,
                    subtasks: [Subtask.mock3]
                )
            ]
        },
        claimTask: { _, staffId in
            var task = AgentTask.mock1
            task.assignedStaffId = staffId
            task.claimedAt = Date()
            task.status = .claimed
            return task
        },
        claimActivity: { _, staffId in
            var task = Activity.mock1
            task.assignedStaffId = staffId
            task.claimedAt = Date()
            task.status = .claimed
            return task
        },
        deleteTask: { _, _ in },
        deleteActivity: { _, _ in },
        completeSubtask: { _ in
            var subtask = Subtask.mock1
            subtask.completedAt = Date()
            return subtask
        },
        uncompleteSubtask: { _ in
            var subtask = Subtask.mock1
            subtask.completedAt = nil
            return subtask
        },
        fetchTasksByRealtor: { _ in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            return [
                TaskWithMessages(task: AgentTask.mock1, messages: [SlackMessage.mock1]),
                TaskWithMessages(task: AgentTask.mock2, messages: [])
            ]
        },
        fetchActivitiesByRealtor: { _ in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            return [
                ActivityWithDetails(
                    task: Activity.mock1,
                    listing: Listing.mock1,
                    subtasks: [Subtask.mock1]
                ),
                ActivityWithDetails(
                    task: Activity.mock2,
                    listing: Listing.mock2,
                    subtasks: []
                )
            ]
        },
        fetchCompletedTasks: {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            // Return empty array - no completed tasks in mock data yet
            return []
        }
    )
}
