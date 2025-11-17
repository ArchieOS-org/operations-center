//
//  AdminTeamStore.swift
//  Operations Center
//
//  Admin team view store - shows all admin tasks/activities
//

import Foundation
import OperationsCenterKit
import Dependencies

@Observable @MainActor
final class AdminTeamStore {
    // MARK: - Observable State

    var tasks: [TaskWithMessages] = []
    var activities: [ActivityWithDetails] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let taskRepository: TaskRepositoryClient
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    init(taskRepository: TaskRepositoryClient) {
        self.taskRepository = taskRepository
    }

    // MARK: - Computed Properties

    /// All admin tasks (standalone + property-linked activities)
    var allAdminItems: Int {
        tasks.count + activities.count
    }

    /// Loads admin-category tasks and activities into the store.
    /// 
    /// Fetches tasks and activities concurrently, filters each to items whose `task.taskCategory` equals `.admin`, and updates the store's `tasks` and `activities`. Sets `isLoading` for the duration of the operation and assigns `errorMessage` if the load fails.

    func loadAdminTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all tasks and activities, filter to admin category only
            async let tasksResult = taskRepository.fetchTasks()
            async let activitiesResult = taskRepository.fetchActivities()

            let (allTasks, allActivities) = try await (tasksResult, activitiesResult)

            // Filter to admin category only
            tasks = allTasks.filter { $0.task.taskCategory == .admin }
            activities = allActivities.filter { $0.task.taskCategory == .admin }

        } catch {
            errorMessage = "Failed to load admin tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Toggles the expansion state for the task with the given identifier.
    /// - Parameter taskId: The identifier of the task to expand; if that task is currently expanded it will be collapsed, otherwise it will be expanded.

    func toggleExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
        }
    }

    /// Claim the given agent task for the current user and refresh admin items.
    /// - Parameters:
    ///   - task: The agent task to claim on behalf of the currently authenticated user.
    /// On success the store reloads its admin tasks and activities; on failure `errorMessage` is set with the failure description.
    func claimTask(_ task: AgentTask) async {
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimTask(task.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Attempts to claim the given activity on behalf of the current authenticated user and refreshes the admin task/activity lists.
    /// On success the store reloads admin items; on failure `errorMessage` is set with a descriptive message.
    /// - Parameter activity: The activity to claim.
    func claimActivity(_ activity: Activity) async {
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimActivity(activity.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    /// Deletes the specified admin task and refreshes the admin task/activity lists on success.
    /// - Parameters:
    ///   - task: The `AgentTask` to delete. On successful deletion the store reloads admin tasks; on failure `errorMessage` is set with a descriptive message.
    func deleteTask(_ task: AgentTask) async {
        let userId = authClient.currentUserId()

        do {
            try await taskRepository.deleteTask(task.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Deletes the given activity from the repository and refreshes the admin task/activity lists.
    /// - Parameters:
    ///   - activity: The activity to delete.
    /// - Note: On success the store reloads admin tasks and activities. On failure `errorMessage` is set with a descriptive message.
    func deleteActivity(_ activity: Activity) async {
        let userId = authClient.currentUserId()

        do {
            try await taskRepository.deleteActivity(activity.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }
}