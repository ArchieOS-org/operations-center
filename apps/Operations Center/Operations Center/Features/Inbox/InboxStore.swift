//
//  InboxStore.swift
//  Operations Center
//
//  Store for inbox view - manages both stray and listing tasks
//

import Foundation
import Observation
import OperationsCenterKit

@Observable
@MainActor
final class InboxStore {
    // MARK: - State

    var tasks: [TaskWithMessages] = []
    var activities: [ActivityWithDetails] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let repository: TaskRepositoryClient

    // MARK: - Initialization

    /// Full initializer with optional initial data for previews
    init(
        repository: TaskRepositoryClient,
        initialStrayTasks: [TaskWithMessages] = [],
        initialListingTasks: [ActivityWithDetails] = []
    ) {
        self.repository = repository
        self.tasks = initialStrayTasks
        self.activities = initialListingTasks
    }

    // MARK: - Public Methods

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch both stray and listing tasks concurrently
            async let stray = repository.fetchTasks()
            async let listing = repository.fetchActivities()

            tasks = try await stray
            activities = try await listing
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await fetchTasks()
    }

    // MARK: - Expansion State

    func toggleExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
        }
    }

    func isExpanded(_ taskId: String) -> Bool {
        expandedTaskId == taskId
    }

    // MARK: - Stray Task Actions

    func claimTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            // Get current user ID - for now use a placeholder
            // swiftlint:disable:next todo
            // TODO: Replace with actual authenticated user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimTask(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteTask(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Listing Task Actions

    func claimActivity(_ task: Activity) async {
        errorMessage = nil

        do {
            // Get current user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimActivity(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteActivity(_ task: Activity) async {
        errorMessage = nil

        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteActivity(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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
}
