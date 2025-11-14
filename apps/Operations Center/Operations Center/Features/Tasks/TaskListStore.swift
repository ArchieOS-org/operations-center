//
//  TaskListStore.swift
//  Operations Center
//
//  Store managing the list of listing tasks using repository pattern
//  Reference: swift-dependencies/Articles/SingleEntryPointSystems.md
//

import Foundation
import Dependencies
import OperationsCenterKit

/// Store managing the list of listing tasks using repository pattern
@Observable
@MainActor
final class TaskListStore {
    // MARK: - Observable State

    var listingTasks: [(task: ListingTask, listing: Listing, subtasks: [Subtask])] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    /// Using @Dependency pattern for Observable stores
    /// Reference: swift-dependencies/Articles/SingleEntryPointSystems.md
    @ObservationIgnored
    @Dependency(\.taskRepository) var repository

    // MARK: - Initializer

    init() {}

    // MARK: - Actions

    /// Fetch all listing tasks from repository
    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            listingTasks = try await repository.fetchListingTasks()
            print("✅ Successfully fetched \(listingTasks.count) tasks")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ Error fetching tasks: \(error)")
        }

        isLoading = false
    }

    /// Claim a task by assigning it to current staff member
    func claimTask(_ task: ListingTask) async {
        do {
            // Get current user ID - for now use a placeholder
            // TODO: Replace with actual authenticated user ID
            let currentUserId = "current-staff-id"

            _ = try await repository.claimListingTask(task.id, currentUserId)

            print("✅ Task claimed: \(task.name)")

            // Refresh to get updated data
            await fetchTasks()
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
            print("❌ Error claiming task: \(error)")
        }
    }

    /// Delete a listing task (soft delete)
    func deleteTask(_ task: ListingTask) async {
        do {
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

            try await repository.deleteListingTask(task.id, currentUserId)

            print("✅ Task deleted: \(task.name)")

            // Refresh to get updated data
            await fetchTasks()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            print("❌ Error deleting task: \(error)")
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
