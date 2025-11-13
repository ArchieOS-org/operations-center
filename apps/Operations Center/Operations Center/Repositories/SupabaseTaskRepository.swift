//
//  SupabaseTaskRepository.swift
//  Operations Center
//
//  Production repository implementation using Supabase
//

import Foundation
import Dependencies
import Supabase
import OperationsCenterKit

/// Production repository implementation using Supabase database
@MainActor
final class SupabaseTaskRepository: TaskRepository {
    // MARK: - Dependencies

    @Dependency(\.supabaseClient) var supabaseClient

    // MARK: - Initialization

    init() {}

    // MARK: - Task Repository Protocol

    /// Fetch all stray tasks with their associated Slack messages
    func fetchStrayTasks() async throws -> [(task: StrayTask, messages: [SlackMessage])] {
        // Fetch stray tasks without nested messages for now
        // TODO: Implement proper nested query handling once Supabase Swift SDK supports it better
        let response: [StrayTask] = try await supabaseClient
            .from("stray_tasks")
            .select()
            .is("deleted_at", value: nil)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value

        // Return tasks with empty messages - nested queries need better handling
        return response.map { ($0, []) }
    }

    /// Fetch all listing tasks with their listing data and subtasks
    func fetchListingTasks() async throws -> [(task: ListingTask, listing: Listing, subtasks: [Subtask])] {
        // Query listing_tasks with nested listings join
        // PostgREST syntax: select=*,listings(*)
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

        let response: [ListingTaskResponse] = try await supabaseClient
            .from("listing_tasks")
            .select("*, listings(*)")
            .is("deleted_at", value: nil)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value

        return try response.compactMap { row in
            guard let listing = row.listing else {
                print("⚠️ Warning: listing_task \(row.taskId) missing listing data")
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
    }

    /// Claim a stray task
    func claimStrayTask(taskId: String, staffId: String) async throws -> StrayTask {
        let now = Date()

        let response: StrayTask = try await supabaseClient
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
    }

    /// Claim a listing task
    func claimListingTask(taskId: String, staffId: String) async throws -> ListingTask {
        let now = Date()

        let response: ListingTask = try await supabaseClient
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
    }

    /// Delete a stray task (soft delete)
    func deleteStrayTask(taskId: String, deletedBy: String) async throws {
        let now = Date()

        try await supabaseClient
            .from("stray_tasks")
            .update([
                "deleted_at": now.ISO8601Format(),
                "deleted_by": deletedBy
            ])
            .eq("task_id", value: taskId)
            .execute()
    }

    /// Delete a listing task (soft delete)
    func deleteListingTask(taskId: String, deletedBy: String) async throws {
        let now = Date()

        try await supabaseClient
            .from("listing_tasks")
            .update([
                "deleted_at": now.ISO8601Format(),
                "deleted_by": deletedBy
            ])
            .eq("task_id", value: taskId)
            .execute()
    }

    /// Complete a subtask within a listing task
    func completeSubtask(subtaskId: String) async throws -> Subtask {
        // TODO: Implement once subtasks table exists
        throw NSError(domain: "SupabaseTaskRepository", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
        ])
    }

    /// Uncomplete a subtask within a listing task
    func uncompleteSubtask(subtaskId: String) async throws -> Subtask {
        // TODO: Implement once subtasks table exists
        throw NSError(domain: "SupabaseTaskRepository", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
        ])
    }
}
