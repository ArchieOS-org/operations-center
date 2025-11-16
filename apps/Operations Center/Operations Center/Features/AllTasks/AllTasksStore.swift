//
//  AllTasksStore.swift
//  Operations Center
//
//  All Tasks screen store - shows all claimed tasks system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 286-305
//

import Foundation
import OperationsCenterKit
import OSLog
import SwiftUI

/// Store for All Tasks screen - all claimed tasks across the entire system
/// Per spec: "All claimed Tasks system-wide (standalone + assigned to listings)"
@MainActor
@Observable
final class AllTasksStore {
    // MARK: - Properties

    /// All agent tasks (standalone tasks)
    private(set) var tasks: [TaskWithMessages] = []

    /// All activitys (property-linked tasks)
    private(set) var activities: [ActivityWithDetails] = []

    /// Currently expanded task ID (only one can be expanded at a time)
    var expandedTaskId: String?

    /// Filter by team: marketing, admin, or all
    var teamFilter: OperationsCenterKit.TeamFilter = .all

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repository for data access
    private let repository: TaskRepositoryClient

    // MARK: - Initialization

    init(repository: TaskRepositoryClient) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Fetch all claimed tasks
    func fetchAllTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            async let tasksFetch = repository.fetchTasks()
            async let activitiesFetch = repository.fetchActivities()

            let (stray, listing) = try await (tasksFetch, activitiesFetch)

            // Filter only claimed tasks
            tasks = stray.filter { $0.task.status == .claimed || $0.task.status == .inProgress }
            activities = listing.filter { $0.task.status == .claimed || $0.task.status == .inProgress }

            Logger.tasks.info(
                "Fetched \(self.tasks.count) agent tasks and \(self.activities.count) activitys"
            )
        } catch {
            Logger.tasks.error("Failed to fetch all tasks: \(error.localizedDescription)")
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await fetchAllTasks()
    }

    /// Toggle expansion for a task
    func toggleExpansion(for taskId: String) {
        expandedTaskId = expandedTaskId == taskId ? nil : taskId
    }

    /// Claim a agent task
    func claimTask(_ task: AgentTask) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            _ = try await repository.claimTask(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to claim agent task: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Claim a activity
    func claimActivity(_ task: Activity) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            _ = try await repository.claimActivity(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to claim activity: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Delete a agent task
    func deleteTask(_ task: AgentTask) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            try await repository.deleteTask(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to delete agent task: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Delete a activity
    func deleteActivity(_ task: Activity) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            try await repository.deleteActivity(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to delete activity: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    /// Filtered agent tasks based on team filter
    var filteredTasks: [TaskWithMessages] {
        switch teamFilter {
        case .all:
            return tasks
        case .marketing:
            return tasks.filter { $0.task.taskCategory == .marketing }
        case .admin:
            return tasks.filter { $0.task.taskCategory == .admin }
        }
    }

    /// Filtered activitys based on team filter
    var filteredActivities: [ActivityWithDetails] {
        switch teamFilter {
        case .all:
            return activities
        case .marketing:
            return activities.filter { $0.task.visibilityGroup == .marketing || $0.task.visibilityGroup == .both }
        case .admin:
            return activities.filter { $0.task.visibilityGroup == .agent || $0.task.visibilityGroup == .both }
        }
    }
}
