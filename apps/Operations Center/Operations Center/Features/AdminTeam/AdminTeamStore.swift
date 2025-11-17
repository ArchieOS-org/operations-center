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

    // MARK: - Data Loading

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

    // MARK: - Actions

    func toggleExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
        }
    }

    func claimTask(_ task: AgentTask) async {
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimTask(task.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    func claimActivity(_ activity: Activity) async {
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimActivity(activity.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    func deleteTask(_ task: AgentTask) async {
        let userId = authClient.currentUserId()

        do {
            try await taskRepository.deleteTask(task.id, userId)
            await loadAdminTasks() // Refresh
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

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
