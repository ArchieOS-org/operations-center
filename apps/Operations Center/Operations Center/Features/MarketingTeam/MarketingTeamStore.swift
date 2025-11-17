//
//  MarketingTeamStore.swift
//  Operations Center
//
//  Marketing team view store - shows all marketing tasks/activities
//

import Foundation
import OperationsCenterKit
import Dependencies

@Observable @MainActor
final class MarketingTeamStore {
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

    /// All marketing tasks (standalone + property-linked activities)
    var allMarketingItems: Int {
        tasks.count + activities.count
    }

    /// Fetches marketing tasks and activities and updates the store's state.
    /// 
    /// On success, updates `tasks` and `activities` to contain only items whose `task.taskCategory` is `.marketing`.
    /// It sets `isLoading` to `true` at the start and to `false` when finished. `errorMessage` is cleared before loading
    /// and set to a descriptive message if fetching fails.

    func loadMarketingTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all tasks and activities, filter to marketing category only
            async let tasksResult = taskRepository.fetchTasks()
            async let activitiesResult = taskRepository.fetchActivities()

            let (allTasks, allActivities) = try await (tasksResult, activitiesResult)

            // Filter to marketing category only
            tasks = allTasks.filter { $0.task.taskCategory == .marketing }
            activities = allActivities.filter { $0.task.taskCategory == .marketing }

        } catch {
            errorMessage = "Failed to load marketing tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Toggles which task is expanded in the UI.
    /// - Parameter taskId: The identifier of the task to expand or collapse. If this task is already expanded, it will be collapsed; otherwise it will be set as the expanded task.

    func toggleExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
        }
    }

    /// Claims the specified task for the current user and reloads marketing tasks and activities.
    /// 
    /// If the claim fails, updates `errorMessage` with a descriptive failure message.
    /// - Parameter task: The task to claim.
    func claimTask(_ task: AgentTask) async {
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimTask(task.id, userId)
            await loadMarketingTasks() // Refresh
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Claims the specified activity on behalf of the current authenticated user and refreshes marketing items.
    /// - Parameter activity: The activity to claim.
    /// - Note: On failure, updates `errorMessage` with a descriptive message.
    func claimActivity(_ activity: Activity) async {
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimActivity(activity.id, userId)
            await loadMarketingTasks() // Refresh
        } catch {
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    /// Deletes the specified task on behalf of the current user and refreshes the store.
    /// If deletion fails, sets `errorMessage` with a descriptive message.
    /// - Parameter task: The task to delete.
    func deleteTask(_ task: AgentTask) async {
        let userId = authClient.currentUserId()

        do {
            try await taskRepository.deleteTask(task.id, userId)
            await loadMarketingTasks() // Refresh
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Deletes the specified activity on behalf of the current user and refreshes the store's marketing items.
    /// - Parameter activity: The activity to delete. On successful deletion the store reloads marketing tasks and activities; on failure `errorMessage` is set with the failure description.
    func deleteActivity(_ activity: Activity) async {
        let userId = authClient.currentUserId()

        do {
            try await taskRepository.deleteActivity(activity.id, userId)
            await loadMarketingTasks() // Refresh
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }
}