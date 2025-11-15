//
//  TaskRepositoryClient.swift
//  Operations Center
//
//  Task repository client using native Swift patterns
//

import Foundation
import OSLog
import OperationsCenterKit
import Supabase

// MARK: - Task Repository Client

/// Task repository client for production and preview contexts
public struct TaskRepositoryClient {
    /// Fetch all stray tasks with their associated Slack messages
    public var fetchStrayTasks: @Sendable () async throws -> [(task: StrayTask, messages: [SlackMessage])]

    /// Fetch all listing tasks with their listing data and subtasks
    public var fetchListingTasks: @Sendable () async throws
        -> [(task: ListingTask, listing: Listing, subtasks: [Subtask])]

    /// Claim a stray task
    public var claimStrayTask: @Sendable (_ taskId: String, _ staffId: String) async throws -> StrayTask

    /// Claim a listing task
    public var claimListingTask: @Sendable (_ taskId: String, _ staffId: String) async throws -> ListingTask

    /// Delete a stray task (soft delete)
    public var deleteStrayTask: @Sendable (_ taskId: String, _ deletedBy: String) async throws -> Void

    /// Delete a listing task (soft delete)
    public var deleteListingTask: @Sendable (_ taskId: String, _ deletedBy: String) async throws -> Void

    /// Complete a subtask within a listing task
    public var completeSubtask: @Sendable (_ subtaskId: String) async throws -> Subtask

    /// Uncomplete a subtask within a listing task
    public var uncompleteSubtask: @Sendable (_ subtaskId: String) async throws -> Subtask
}

// MARK: - Live Implementation

extension TaskRepositoryClient {
    /// Production implementation using global Supabase client
    public static let live = Self(
            fetchStrayTasks: {
                let response: [StrayTask] = try await supabase
                    .from("stray_tasks")
                    .select()
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                // Return tasks with empty messages - nested queries need better handling
                return response.map { ($0, []) }
            },
            fetchListingTasks: {
                // Query listing_tasks with nested listings join
                struct ListingTaskResponse: Decodable {
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

                let response: [ListingTaskResponse] = try await supabase
                    .from("listing_tasks")
                    .select("*, listings(*)")
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return response.compactMap { row -> (task: ListingTask, listing: Listing, subtasks: [Subtask])? in
                    guard let listing = row.listing else {
                        Logger.database.warning("Listing task missing listing data: \(row.taskId)")
                        return nil
                    }

                    let task = ListingTask(
                        id: row.taskId,
                        listingId: row.listingId,
                        realtorId: row.realtorId,
                        name: row.name,
                        description: row.description,
                        taskCategory: ListingTask.TaskCategory(rawValue: row.taskCategory) ?? .other,
                        status: ListingTask.TaskStatus(rawValue: row.status) ?? .open,
                        priority: row.priority,
                        visibilityGroup: ListingTask.VisibilityGroup(rawValue: row.visibilityGroup) ?? .both,
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

                    // TODO: Add subtasks query once subtasks table exists
                    let subtasks: [Subtask] = []

                    return (task, listing, subtasks)
                }
            },
            claimStrayTask: { taskId, staffId in
                let now = Date()

                let response: StrayTask = try await supabase
                    .from("stray_tasks")
                    .update([
                        "assigned_staff_id": staffId,
                        "claimed_at": now.ISO8601Format(),
                        "status": StrayTask.TaskStatus.claimed.rawValue
                    ])
                    .eq("task_id", value: taskId)
                    .select()
                    .single()
                    .execute()
                    .value

                return response
            },
            claimListingTask: { taskId, staffId in
                let now = Date()

                let response: ListingTask = try await supabase
                    .from("listing_tasks")
                    .update([
                        "assigned_staff_id": staffId,
                        "claimed_at": now.ISO8601Format(),
                        "status": ListingTask.TaskStatus.claimed.rawValue
                    ])
                    .eq("task_id", value: taskId)
                    .select()
                    .single()
                    .execute()
                    .value

                return response
            },
            deleteStrayTask: { taskId, deletedBy in
                let now = Date()

                try await supabase
                    .from("stray_tasks")
                    .update([
                        "deleted_at": now.ISO8601Format(),
                        "deleted_by": deletedBy
                    ])
                    .eq("task_id", value: taskId)
                    .execute()
            },
            deleteListingTask: { taskId, deletedBy in
                let now = Date()

                try await supabase
                    .from("listing_tasks")
                    .update([
                        "deleted_at": now.ISO8601Format(),
                        "deleted_by": deletedBy
                    ])
                    .eq("task_id", value: taskId)
                    .execute()
            },
            completeSubtask: { _ in
                // TODO: Implement once subtasks table exists
                throw NSError(domain: "TaskRepositoryClient", code: 501, userInfo: [
                    NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
                ])
            },
            uncompleteSubtask: { _ in
                // TODO: Implement once subtasks table exists
                throw NSError(domain: "TaskRepositoryClient", code: 501, userInfo: [
                    NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
                ])
            }
        )
    }

// MARK: - Preview Implementation

extension TaskRepositoryClient {
    /// Preview implementation with mock data for Xcode previews
    public static let preview = Self(
        fetchStrayTasks: {
            [
                (StrayTask.mock1, [SlackMessage.mock1]),
                (StrayTask.mock2, []),
                (StrayTask.mock3, [SlackMessage.mock2])
            ]
        },
        fetchListingTasks: {
            [
                (ListingTask.mock1, Listing.mock1, [Subtask.mock1, Subtask.mock2]),
                (ListingTask.mock2, Listing.mock2, []),
                (ListingTask.mock3, Listing.mock3, [Subtask.mock3])
            ]
        },
        claimStrayTask: { _, staffId in
            var task = StrayTask.mock1
            task.assignedStaffId = staffId
            task.claimedAt = Date()
            task.status = .claimed
            return task
        },
        claimListingTask: { _, staffId in
            var task = ListingTask.mock1
            task.assignedStaffId = staffId
            task.claimedAt = Date()
            task.status = .claimed
            return task
        },
        deleteStrayTask: { _, _ in },
        deleteListingTask: { _, _ in },
        completeSubtask: { _ in
            var subtask = Subtask.mock1
            subtask.completedAt = Date()
            return subtask
        },
        uncompleteSubtask: { _ in
            var subtask = Subtask.mock1
            subtask.completedAt = nil
            return subtask
        }
    )
}
