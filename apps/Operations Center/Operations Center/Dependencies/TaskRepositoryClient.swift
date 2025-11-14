//
//  TaskRepositoryClient.swift
//  Operations Center
//
//  Task repository dependency client following swift-dependencies pattern
//  Reference: swift-dependencies/Articles/DesigningDependencies.md
//

import Foundation
import Dependencies
import IssueReporting
import OperationsCenterKit
import Supabase

// MARK: - Dependency Client

/// Task repository client for dependency injection
/// Using reportIssue for device-safe unimplemented behavior
/// Reference: swift-dependencies/Articles/DesigningDependencies.md
public struct TaskRepositoryClient {
    /// Fetch all stray tasks with their associated Slack messages
    public var fetchStrayTasks: @Sendable () async throws -> [(task: StrayTask, messages: [SlackMessage])]

    /// Fetch all listing tasks with their listing data and subtasks
    public var fetchListingTasks: @Sendable () async throws -> [(task: ListingTask, listing: Listing, subtasks: [Subtask])]

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

// MARK: - DependencyKey Conformance

extension TaskRepositoryClient: DependencyKey {
    /// Live implementation using Supabase
    /// Reference: swift-dependencies/Articles/RegisteringDependencies.md
    public static var liveValue: Self {
        // Use compile-time environment detection
        // Reference: External Research - Launch arguments don't persist on device
        // Reference: Context7 - swift-dependencies conditional compilation
        if AppConfig.Environment.current == .preview {
            return previewValue
        }

        // Capture dependency OUTSIDE @Sendable closures to avoid Swift 6 key path isolation errors
        @Dependency(\.supabaseClient) var supabaseClient

        return Self(
            fetchStrayTasks: {
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

                let response: [ListingTaskResponse] = try await supabaseClient
                    .from("listing_tasks")
                    .select("*, listings(*)")
                    .is("deleted_at", value: nil)
                    .order("priority", ascending: false)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return response.compactMap { row -> (task: ListingTask, listing: Listing, subtasks: [Subtask])? in
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
            },
            claimStrayTask: { taskId, staffId in
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
            },
            claimListingTask: { taskId, staffId in
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
            },
            deleteStrayTask: { taskId, deletedBy in
                let now = Date()

                try await supabaseClient
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

                try await supabaseClient
                    .from("listing_tasks")
                    .update([
                        "deleted_at": now.ISO8601Format(),
                        "deleted_by": deletedBy
                    ])
                    .eq("task_id", value: taskId)
                    .execute()
            },
            completeSubtask: { subtaskId in
                // TODO: Implement once subtasks table exists
                throw NSError(domain: "TaskRepositoryClient", code: 501, userInfo: [
                    NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
                ])
            },
            uncompleteSubtask: { subtaskId in
                // TODO: Implement once subtasks table exists
                throw NSError(domain: "TaskRepositoryClient", code: 501, userInfo: [
                    NSLocalizedDescriptionKey: "Subtasks table not yet implemented"
                ])
            }
        )
    }

    /// Preview implementation with mock data
    /// Mock data lives here per Context7 best practice
    /// Reference: swift-dependencies/Articles/LivePreviewTest.md
    public static let previewValue = Self(
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
        claimStrayTask: { taskId, staffId in
            var task = StrayTask.mock1
            task.assignedStaffId = staffId
            task.claimedAt = Date()
            task.status = .claimed
            return task
        },
        claimListingTask: { taskId, staffId in
            var task = ListingTask.mock1
            task.assignedStaffId = staffId
            task.claimedAt = Date()
            task.status = .claimed
            return task
        },
        deleteStrayTask: { _, _ in },
        deleteListingTask: { _, _ in },
        completeSubtask: { subtaskId in
            var subtask = Subtask.mock1
            subtask.completedAt = Date()
            return subtask
        },
        uncompleteSubtask: { subtaskId in
            var subtask = Subtask.mock1
            subtask.completedAt = nil
            return subtask
        }
    )

    /// Test implementation - uses reportIssue for device-safe unimplemented behavior
    /// reportIssue triggers runtime warnings without crashing on device
    /// Reference: xctest-dynamic-overlay/Articles/GettingStarted.md
    public static let testValue = Self(
        fetchStrayTasks: {
            reportIssue("TaskRepositoryClient.fetchStrayTasks unimplemented in test")
            return []
        },
        fetchListingTasks: {
            reportIssue("TaskRepositoryClient.fetchListingTasks unimplemented in test")
            return []
        },
        claimStrayTask: { taskId, staffId in
            reportIssue("TaskRepositoryClient.claimStrayTask unimplemented in test")
            return StrayTask.mock1
        },
        claimListingTask: { taskId, staffId in
            reportIssue("TaskRepositoryClient.claimListingTask unimplemented in test")
            return ListingTask.mock1
        },
        deleteStrayTask: { taskId, deletedBy in
            reportIssue("TaskRepositoryClient.deleteStrayTask unimplemented in test")
        },
        deleteListingTask: { taskId, deletedBy in
            reportIssue("TaskRepositoryClient.deleteListingTask unimplemented in test")
        },
        completeSubtask: { subtaskId in
            reportIssue("TaskRepositoryClient.completeSubtask unimplemented in test")
            return Subtask.mock1
        },
        uncompleteSubtask: { subtaskId in
            reportIssue("TaskRepositoryClient.uncompleteSubtask unimplemented in test")
            return Subtask.mock1
        }
    )
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    /// Access task repository via dependency system
    /// Reference: swift-dependencies/Articles/RegisteringDependencies.md
    public var taskRepository: TaskRepositoryClient {
        get { self[TaskRepositoryClient.self] }
        set { self[TaskRepositoryClient.self] = newValue }
    }
}