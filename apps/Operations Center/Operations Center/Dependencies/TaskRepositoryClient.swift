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

// swiftlint:disable file_length
/// Task repository client for production and preview contexts
public struct TaskRepositoryClient {
    /// Fetch all tasks with their associated Slack messages
    public var fetchTasks: @Sendable () async throws -> [TaskWithMessages]

    /// Fetch all activities with their listing data and activity items
    public var fetchActivities: @Sendable () async throws -> [ActivityWithDetails]

    /// Fetch deleted tasks (for Logbook)
    public var fetchDeletedTasks: @Sendable () async throws -> [AgentTask]

    /// Fetch deleted activities (for Logbook)
    public var fetchDeletedActivities: @Sendable () async throws -> [ActivityWithDetails]

    /// Claim a task
    public var claimTask: @Sendable (_ taskId: String, _ staffId: String) async throws -> AgentTask

    /// Claim an activity
    public var claimActivity: @Sendable (_ taskId: String, _ staffId: String) async throws -> Activity

    /// Delete a task (soft delete)
    public var deleteTask: @Sendable (_ taskId: String, _ deletedBy: String) async throws -> Void

    /// Delete an activity (soft delete)
    public var deleteActivity: @Sendable (_ taskId: String, _ deletedBy: String) async throws -> Void

    /// Fetch tasks for a specific realtor
    public var fetchTasksByRealtor: @Sendable (_ realtorId: String) async throws -> [TaskWithMessages]

    /// Fetch activities for a specific realtor
    public var fetchActivitiesByRealtor: @Sendable (_ realtorId: String) async throws -> [ActivityWithDetails]

    /// Fetch completed tasks (for Logbook)
    public var fetchCompletedTasks: @Sendable () async throws -> [AgentTask]

    /// Fetch activities by assigned staff member (for My Listings)
    public var fetchActivitiesByStaff: @Sendable (_ staffId: String) async throws -> [ActivityWithDetails]
}

// MARK: - Response Models

/// Decodable response model for activities with nested listings join
private struct ActivityResponse: Decodable {
    let taskId: String
    let listingId: String
    let realtorId: String?
    let name: String
    let description: String?
    let taskCategory: String?  // Optional - can be NULL in database
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
        taskCategory: row.taskCategory.flatMap(TaskCategory.init(rawValue:)),  // Optional: admin, marketing, or nil
        status: TaskStatus(rawValue: row.status) ?? .open,
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

    return ActivityWithDetails(task: task, listing: listing)
}

// MARK: - Live Implementation

extension TaskRepositoryClient {
    /// Production implementation with local-first architecture for activities
    public static func live(localDatabase: LocalDatabase) -> Self {
        return Self(
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
                Logger.database.info("🔍 TaskRepository.fetchActivities() - Reading from local database...")

                // Read from local database first for instant UI
                let cachedActivities = try await MainActor.run { try localDatabase.fetchActivities() }
                Logger.database.info("📱 Local database returned \(cachedActivities.count) activities")

                // We need listings to create ActivityWithDetails
                let cachedListings = try await MainActor.run { try localDatabase.fetchListings() }
                let listingsById = Dictionary(uniqueKeysWithValues: cachedListings.map { ($0.id, $0) })

                // Map cached activities to ActivityWithDetails
                let cachedWithDetails = cachedActivities.compactMap { activity -> ActivityWithDetails? in
                    guard let listing = listingsById[activity.listingId] else {
                        return nil
                    }
                    return ActivityWithDetails(task: activity, listing: listing)
                }

                // Background refresh from Supabase
                Task.detached {
                    do {
                        Logger.database.info("☁️ Refreshing activities from Supabase...")
                        let response: [ActivityResponse] = try await supabase
                            .from("activities")
                            .select("*, listings(*)")
                            .is("deleted_at", value: nil)
                            .order("priority", ascending: false)
                            .order("created_at", ascending: false)
                            .execute()
                            .value

                        Logger.database.info("✅ Supabase returned \(response.count) activity records")

                        // Extract activities and listings from response
                        let activities = response.compactMap { row -> Activity? in
                            Activity(
                                id: row.taskId,
                                listingId: row.listingId,
                                realtorId: row.realtorId,
                                name: row.name,
                                description: row.description,
                                taskCategory: row.taskCategory.flatMap(TaskCategory.init(rawValue:)),
                                status: TaskStatus(rawValue: row.status) ?? .open,
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
                        }

                        let listings = response.compactMap { $0.listing }

                        // Persist to local database
                        try await MainActor.run { try localDatabase.upsertActivities(activities) }
                        try await MainActor.run { try localDatabase.upsertListings(listings) }
                        Logger.database.info("💾 Saved \(activities.count) activities and \(listings.count) listings to local database")
                    } catch {
                        Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                    }
                }

                return cachedWithDetails
            },
            fetchDeletedTasks: {
                Logger.database.info("Fetching deleted tasks")
                // Fetch deleted tasks: deleted_at IS NOT NULL
                let tasks: [AgentTask] = try await supabase
                    .from("agent_tasks")
                    .select()
                    .filter("deleted_at", operator: "not.is.null", value: "")
                    .order("deleted_at", ascending: false)
                    .execute()
                    .value

                Logger.database.info("Fetched \(tasks.count) deleted agent tasks")
                return tasks
            },
            fetchDeletedActivities: {
                Logger.database.info("Fetching deleted activities")
                // Fetch deleted activities: deleted_at IS NOT NULL
                let response: [ActivityResponse] = try await supabase
                    .from("activities")
                    .select("*, listings(*)")
                    .filter("deleted_at", operator: "not.is.null", value: "")
                    .order("deleted_at", ascending: false)
                    .execute()
                    .value

                Logger.database.info("Fetched \(response.count) deleted activities")
                return response.compactMap(mapActivityResponse)
            },
            claimTask: { taskId, staffId in
                let now = Date()

                let response: AgentTask = try await supabase
                    .from("agent_tasks")
                    .update([
                        "assigned_staff_id": staffId,
                        "claimed_at": now.ISO8601Format(),
                        "status": TaskStatus.claimed.rawValue
                    ])
                    .eq("task_id", value: taskId)
                    .select()
                    .single()
                    .execute()
                    .value

                return response
            },
            claimActivity: { taskId, staffId in
                Logger.database.info("✋ TaskRepository.claimActivity(\(taskId))")
                let now = Date()

                // Update Supabase first
                let response: Activity = try await supabase
                    .from("activities")
                    .update([
                        "assigned_staff_id": staffId,
                        "claimed_at": now.ISO8601Format(),
                        "status": TaskStatus.claimed.rawValue
                    ])
                    .eq("task_id", value: taskId)
                    .select()
                    .single()
                    .execute()
                    .value

                Logger.database.info("✅ Supabase updated activity")

                // Update local database
                try await MainActor.run { try localDatabase.upsertActivities([response]) }
                Logger.database.info("💾 Updated local database with claimed activity")

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
                Logger.database.info("🗑️ TaskRepository.deleteActivity(\(taskId))")
                let now = Date()

                // Update Supabase first
                try await supabase
                    .from("activities")
                    .update([
                        "deleted_at": now.ISO8601Format(),
                        "deleted_by": deletedBy
                    ])
                    .eq("task_id", value: taskId)
                    .execute()

                Logger.database.info("✅ Supabase marked activity as deleted")

                // Update local database - fetch and mark as deleted
                let cachedActivities = try await MainActor.run { try localDatabase.fetchActivities() }
                if let activity = cachedActivities.first(where: { $0.id == taskId }) {
                    let deletedActivity = Activity(
                        id: activity.id,
                        listingId: activity.listingId,
                        realtorId: activity.realtorId,
                        name: activity.name,
                        description: activity.description,
                        taskCategory: activity.taskCategory,
                        status: activity.status,
                        priority: activity.priority,
                        visibilityGroup: activity.visibilityGroup,
                        assignedStaffId: activity.assignedStaffId,
                        dueDate: activity.dueDate,
                        claimedAt: activity.claimedAt,
                        completedAt: activity.completedAt,
                        createdAt: activity.createdAt,
                        updatedAt: activity.updatedAt,
                        deletedAt: now,
                        deletedBy: deletedBy,
                        inputs: activity.inputs,
                        outputs: activity.outputs
                    )
                    try await MainActor.run { try localDatabase.upsertActivities([deletedActivity]) }
                    Logger.database.info("💾 Updated local database with deletion")
                }
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
                Logger.database.info("🔍 TaskRepository.fetchActivitiesByRealtor(\(realtorId)) - Reading from local database...")

                // Read from local database first - filter by realtor_id
                let allCached = try await MainActor.run { try localDatabase.fetchActivities() }
                let cachedForRealtor = allCached.filter { $0.realtorId == realtorId }
                Logger.database.info("📱 Local database returned \(cachedForRealtor.count) activities for realtor")

                // Get listings for ActivityWithDetails
                let cachedListings = try await MainActor.run { try localDatabase.fetchListings() }
                let listingsById = Dictionary(uniqueKeysWithValues: cachedListings.map { ($0.id, $0) })

                let cachedWithDetails = cachedForRealtor.compactMap { activity -> ActivityWithDetails? in
                    guard let listing = listingsById[activity.listingId] else {
                        return nil
                    }
                    return ActivityWithDetails(task: activity, listing: listing)
                }

                // Background refresh from Supabase
                Task.detached {
                    do {
                        Logger.database.info("☁️ Refreshing realtor \(realtorId) activities from Supabase...")
                        let response: [ActivityResponse] = try await supabase
                            .from("activities")
                            .select("*, listings(*)")
                            .eq("realtor_id", value: realtorId)
                            .is("deleted_at", value: nil)
                            .order("priority", ascending: false)
                            .order("created_at", ascending: false)
                            .execute()
                            .value

                        Logger.database.info("✅ Supabase returned \(response.count) activities for realtor")

                        // Extract and persist
                        let activities = response.compactMap { row -> Activity? in
                            Activity(
                                id: row.taskId,
                                listingId: row.listingId,
                                realtorId: row.realtorId,
                                name: row.name,
                                description: row.description,
                                taskCategory: row.taskCategory.flatMap(TaskCategory.init(rawValue:)),
                                status: TaskStatus(rawValue: row.status) ?? .open,
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
                        }

                        let listings = response.compactMap { $0.listing }

                        try await MainActor.run { try localDatabase.upsertActivities(activities) }
                        try await MainActor.run { try localDatabase.upsertListings(listings) }
                        Logger.database.info("💾 Saved activities and listings to local database")
                    } catch {
                        Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                    }
                }

                return cachedWithDetails
            },
            fetchCompletedTasks: {
                Logger.database.info("Fetching completed tasks")
                let tasks: [AgentTask] = try await supabase
                    .from("agent_tasks")
                    .select()
                    .eq("status", value: TaskStatus.done.rawValue)
                    .is("deleted_at", value: nil)
                    .order("completed_at", ascending: false)
                    .execute()
                    .value

                Logger.database.info("Fetched \(tasks.count) completed agent tasks")
                return tasks
            },
            fetchActivitiesByStaff: { staffId in
                Logger.database.info("🔍 TaskRepository.fetchActivitiesByStaff(\(staffId)) - Reading from local database...")

                // Read from local database first - filter by assigned_staff_id
                let allCached = try await MainActor.run { try localDatabase.fetchActivities() }
                let cachedForStaff = allCached.filter { $0.assignedStaffId == staffId }
                Logger.database.info("📱 Local database returned \(cachedForStaff.count) activities for staff")

                // Get listings for ActivityWithDetails
                let cachedListings = try await MainActor.run { try localDatabase.fetchListings() }
                let listingsById = Dictionary(uniqueKeysWithValues: cachedListings.map { ($0.id, $0) })

                let cachedWithDetails = cachedForStaff.compactMap { activity -> ActivityWithDetails? in
                    guard let listing = listingsById[activity.listingId] else {
                        return nil
                    }
                    return ActivityWithDetails(task: activity, listing: listing)
                }

                // Background refresh from Supabase
                Task.detached {
                    do {
                        Logger.database.info("☁️ Refreshing staff \(staffId) activities from Supabase...")
                        let response: [ActivityResponse] = try await supabase
                            .from("activities")
                            .select("*, listings(*)")
                            .eq("assigned_staff_id", value: staffId)
                            .is("deleted_at", value: nil)
                            .order("priority", ascending: false)
                            .order("created_at", ascending: false)
                            .execute()
                            .value

                        Logger.database.info("✅ Supabase returned \(response.count) activities for staff")

                        // Extract and persist
                        let activities = response.compactMap { row -> Activity? in
                            Activity(
                                id: row.taskId,
                                listingId: row.listingId,
                                realtorId: row.realtorId,
                                name: row.name,
                                description: row.description,
                                taskCategory: row.taskCategory.flatMap(TaskCategory.init(rawValue:)),
                                status: TaskStatus(rawValue: row.status) ?? .open,
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
                        }

                        let listings = response.compactMap { $0.listing }

                        try await MainActor.run { try localDatabase.upsertActivities(activities) }
                        try await MainActor.run { try localDatabase.upsertListings(listings) }
                        Logger.database.info("💾 Saved activities and listings to local database")
                    } catch {
                        Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                    }
                }

                return cachedWithDetails
            }
        )
    }
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
                    listing: Listing.mock1
                ),
                ActivityWithDetails(
                    task: Activity.mock2,
                    listing: Listing.mock2
                ),
                ActivityWithDetails(
                    task: Activity.mock3,
                    listing: Listing.mock3
                )
            ]
        },
        fetchDeletedTasks: {
            return []
        },
        fetchDeletedActivities: {
            return []
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
        fetchTasksByRealtor: { _ in
            return [
                TaskWithMessages(task: AgentTask.mock1, messages: [SlackMessage.mock1]),
                TaskWithMessages(task: AgentTask.mock2, messages: [])
            ]
        },
        fetchActivitiesByRealtor: { _ in
            return [
                ActivityWithDetails(
                    task: Activity.mock1,
                    listing: Listing.mock1
                ),
                ActivityWithDetails(
                    task: Activity.mock2,
                    listing: Listing.mock2
                )
            ]
        },
        fetchCompletedTasks: {
            // Return empty array - no completed tasks in mock data yet
            return []
        },
        fetchActivitiesByStaff: { _ in
            return [
                ActivityWithDetails(
                    task: Activity.mock1,
                    listing: Listing.mock1
                ),
                ActivityWithDetails(
                    task: Activity.mock2,
                    listing: Listing.mock2
                )
            ]
        }
    )
}
