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

    /// All stray tasks (standalone tasks)
    private(set) var strayTasks: [StrayTaskWithMessages] = []

    /// All listing tasks (property-linked tasks)
    private(set) var listingTasks: [ListingTaskWithDetails] = []

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
            async let strayFetch = repository.fetchStrayTasks()
            async let listingFetch = repository.fetchListingTasks()

            let (stray, listing) = try await (strayFetch, listingFetch)

            // Filter only claimed tasks
            strayTasks = stray.filter { $0.task.status == .claimed || $0.task.status == .inProgress }
            listingTasks = listing.filter { $0.task.status == .claimed || $0.task.status == .inProgress }

            Logger.tasks.info("Fetched \(self.strayTasks.count) stray tasks and \(self.listingTasks.count) listing tasks")
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

    /// Claim a stray task
    func claimStrayTask(_ task: StrayTask) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            _ = try await repository.claimStrayTask(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to claim stray task: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Claim a listing task
    func claimListingTask(_ task: ListingTask) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            _ = try await repository.claimListingTask(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to claim listing task: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Delete a stray task
    func deleteStrayTask(_ task: StrayTask) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            try await repository.deleteStrayTask(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to delete stray task: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Delete a listing task
    func deleteListingTask(_ task: ListingTask) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            try await repository.deleteListingTask(task.id, currentUserId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to delete listing task: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    /// Filtered stray tasks based on team filter
    var filteredStrayTasks: [StrayTaskWithMessages] {
        switch teamFilter {
        case .all:
            return strayTasks
        case .marketing:
            return strayTasks.filter { $0.task.taskCategory == .marketing }
        case .admin:
            return strayTasks.filter { $0.task.taskCategory == .admin }
        }
    }

    /// Filtered listing tasks based on team filter
    var filteredListingTasks: [ListingTaskWithDetails] {
        switch teamFilter {
        case .all:
            return listingTasks
        case .marketing:
            return listingTasks.filter { $0.task.visibilityGroup == .marketing || $0.task.visibilityGroup == .both }
        case .admin:
            return listingTasks.filter { $0.task.visibilityGroup == .agent || $0.task.visibilityGroup == .both }
        }
    }
}
