//
//  InboxStore.swift
//  Operations Center
//
//  Store for inbox view - using dependency injection with @Dependency
//  Manages both stray and listing tasks with expansion state
//  Reference: swift-dependencies/Articles/SingleEntryPointSystems.md
//

import Foundation
import Observation
import Dependencies
import OperationsCenterKit

@Observable
@MainActor
final class InboxStore {
    // MARK: - State

    var strayTasks: [(task: StrayTask, messages: [SlackMessage])] = []
    var listingTasks: [(task: ListingTask, listing: Listing, subtasks: [Subtask])] = []
    var expandedTaskId: String? = nil
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    /// Using @Dependency pattern for Observable stores
    /// Reference: swift-dependencies/Articles/SingleEntryPointSystems.md
    @ObservationIgnored
    @Dependency(\.taskRepository) var repository

    // MARK: - Initialization

    init() {
        // Dependencies are injected automatically via @Dependency
    }

    // MARK: - Public Methods

    func fetchTasks() async {
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

    func claimStrayTask(_ task: StrayTask) async {
        errorMessage = nil

        do {
            // Get current user ID - for now use a placeholder
            // TODO: Replace with actual authenticated user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimStrayTask(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteStrayTask(_ task: StrayTask) async {
        errorMessage = nil

        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteStrayTask(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Listing Task Actions

    func claimListingTask(_ task: ListingTask) async {
        errorMessage = nil

        do {
            // Get current user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimListingTask(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteListingTask(_ task: ListingTask) async {
        errorMessage = nil

        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteListingTask(task.id, currentUserId)

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
