//
//  TaskListStore.swift
//  Operations Center
//
//  Store managing the list of activities
//

import Foundation
import OperationsCenterKit
import OSLog

/// Store managing the list of activities using repository pattern
@Observable
@MainActor
final class TaskListStore {
    // MARK: - Observable State

    var activities: [ActivityWithDetails] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let repository: TaskRepositoryClient

    // MARK: - Initializer

    /// For production: TaskListStore(repository: .live)
    /// For previews: TaskListStore(repository: .preview)
    init(repository: TaskRepositoryClient) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Fetch all activities from repository
    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            activities = try await repository.fetchActivities()
            Logger.tasks.info("Fetched activities: \(self.activities.count)")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            Logger.tasks.error("Failed to fetch activities: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Claim a task by assigning it to current staff member
    func claimTask(_ task: Activity) async {
        do {
            // Get current user ID - for now use a placeholder
            // swiftlint:disable:next todo
            // TODO: Replace with actual authenticated user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimActivity(task.id, currentUserId)

            Logger.tasks.info("Claimed activity: \(task.id) - \(task.name)")

            // Refresh to get updated data
            await fetchTasks()
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
            Logger.tasks.error("Failed to claim activity: \(error.localizedDescription)")
        }
    }

    /// Delete a activity (soft delete)
    func deleteTask(_ task: Activity) async {
        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteActivity(task.id, currentUserId)

            Logger.tasks.info("Deleted activity: \(task.id) - \(task.name)")

            // Refresh to get updated data
            await fetchTasks()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            Logger.tasks.error("Failed to delete activity: \(error.localizedDescription)")
        }
    }

    /// Toggle subtask completion
    func toggleSubtask(_ subtask: Subtask) async {
        errorMessage = nil

        do {
            if subtask.isCompleted {
                _ = try await repository.uncompleteSubtask(subtask.id)
            } else {
                _ = try await repository.completeSubtask(subtask.id)
            }

            // Refresh to get updated subtasks
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Refresh tasks (for pull-to-refresh)
    func refresh() async {
        await fetchTasks()
    }
}
