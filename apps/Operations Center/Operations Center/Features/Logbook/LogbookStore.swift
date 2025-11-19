//
//  LogbookStore.swift
//  Operations Center
//
//  Store for Logbook screen - archive of completed work
//  Per TASK_MANAGEMENT_SPEC.md lines 325-335
//

import Foundation
import OperationsCenterKit
import OSLog

/// Store for Logbook screen - shows completed listings and tasks
/// Per spec: "Archive of completed work"
@Observable
@MainActor
final class LogbookStore {
    // MARK: - Properties

    private(set) var completedListings: [Listing] = []
    private(set) var completedTasks: [AgentTask] = []
    private(set) var deletedTasks: [AgentTask] = []
    private(set) var deletedActivities: [ActivityWithDetails] = []
    var errorMessage: String?
    private(set) var isLoading = false

    private let listingRepository: ListingRepositoryClient
    private let taskRepository: TaskRepositoryClient

    // MARK: - Initialization

    init(
        listingRepository: ListingRepositoryClient,
        taskRepository: TaskRepositoryClient
    ) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
    }

    // MARK: - Data Fetching

    /// Fetch completed items and deleted items from repositories in parallel
    /// Per Context7: Use async let for parallel fetching
    func fetchCompletedItems() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            // Fetch in parallel per Context7 pattern
            async let listingsFetch = listingRepository.fetchCompletedListings()
            async let tasksFetch = taskRepository.fetchCompletedTasks()
            async let deletedTasksFetch = taskRepository.fetchDeletedTasks()
            async let deletedActivitiesFetch = taskRepository.fetchDeletedActivities()

            let (listings, tasks, delTasks, delActivities) = try await (
                listingsFetch, tasksFetch, deletedTasksFetch, deletedActivitiesFetch
            )

            completedListings = listings
            completedTasks = tasks
            deletedTasks = delTasks
            deletedActivities = delActivities

            Logger.database.info(
                """
                Fetched \(self.completedListings.count) completed listings, \
                \(self.completedTasks.count) completed tasks, \
                \(self.deletedTasks.count) deleted tasks, \
                \(self.deletedActivities.count) deleted activities
                """
            )
        } catch {
            Logger.database.error("Failed to fetch completed items: \(error.localizedDescription)")
            errorMessage = "Failed to load archive: \(error.localizedDescription)"
        }
    }

    /// Refresh the completed items
    func refresh() async {
        await fetchCompletedItems()
    }
}
