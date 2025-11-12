//
//  InboxStore.swift
//  OperationsCenterKit
//
//  Store for inbox view - using repository pattern with @Observable
//  Manages both stray and listing tasks with expansion state
//

import Foundation
import Observation

@Observable
@MainActor
public final class InboxStore {
    // MARK: - State

    public var strayTasks: [(task: StrayTask, messages: [SlackMessage])] = []
    public var listingTasks: [(task: ListingTask, subtasks: [Subtask])] = []
    public var expandedTaskIds: Set<String> = []
    public var isLoading = false
    public var errorMessage: String?

    // MARK: - Dependencies

    private let repository: TaskRepository

    // MARK: - Initialization

    public init(repository: TaskRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    public func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch both stray and listing tasks concurrently
            async let stray = repository.fetchStrayTasks()
            async let listing = repository.fetchListingTasks()

            strayTasks = try await stray
            listingTasks = try await listing
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func refresh() async {
        await fetchTasks()
    }

    // MARK: - Expansion State

    public func toggleExpansion(for taskId: String) {
        if expandedTaskIds.contains(taskId) {
            expandedTaskIds.remove(taskId)
        } else {
            expandedTaskIds.insert(taskId)
        }
    }

    public func isExpanded(_ taskId: String) -> Bool {
        expandedTaskIds.contains(taskId)
    }

    // MARK: - Stray Task Actions

    public func claimStrayTask(_ task: StrayTask) async {
        errorMessage = nil

        do {
            // Get current user ID - for now use a placeholder
            // TODO: Replace with actual authenticated user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimStrayTask(taskId: task.id, staffId: currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteStrayTask(_ task: StrayTask) async {
        errorMessage = nil

        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteStrayTask(taskId: task.id, deletedBy: currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Listing Task Actions

    public func claimListingTask(_ task: ListingTask) async {
        errorMessage = nil

        do {
            // Get current user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimListingTask(taskId: task.id, staffId: currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteListingTask(_ task: ListingTask) async {
        errorMessage = nil

        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteListingTask(taskId: task.id, deletedBy: currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func toggleSubtask(_ subtask: Subtask) async {
        errorMessage = nil

        do {
            if subtask.isCompleted {
                _ = try await repository.uncompleteSubtask(subtaskId: subtask.id)
            } else {
                _ = try await repository.completeSubtask(subtaskId: subtask.id)
            }

            // Refresh to get updated subtasks
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
