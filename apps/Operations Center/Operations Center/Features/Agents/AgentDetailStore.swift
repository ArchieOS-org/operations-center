//
//  AgentDetailStore.swift
//  Operations Center
//
//  Agent Detail screen store - manages all work for a specific agent
//  Per TASK_MANAGEMENT_SPEC.md lines 272-283
//

import Foundation
import SwiftUI
import OSLog
import OperationsCenterKit

/// Store managing Agent Detail screen state
/// Shows all listings and tasks for a specific agent (both claimed and unclaimed)
@Observable
@MainActor
final class AgentDetailStore {
    // MARK: - Properties

    private let realtorRepository: RealtorRepositoryClient
    private let taskRepository: TaskRepositoryClient
    private let realtorId: String

    private(set) var realtor: Realtor?
    private(set) var listings: [ListingWithActivities] = []
    private(set) var listingTasks: [ListingTaskWithDetails] = []
    private(set) var strayTasks: [StrayTaskWithMessages] = []

    private(set) var isLoading = false
    var errorMessage: String?

    var expandedTaskId: String?
    var expandedListingId: String?

    // MARK: - Initialization

    init(
        realtorId: String,
        realtorRepository: RealtorRepositoryClient,
        taskRepository: TaskRepositoryClient
    ) {
        self.realtorId = realtorId
        self.realtorRepository = realtorRepository
        self.taskRepository = taskRepository
    }

    // MARK: - Data Fetching

    func fetchAgentData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all data in parallel
            async let realtorFetch = realtorRepository.fetchRealtor(realtorId)
            async let listingsFetch = fetchListingsForAgent()
            async let listingTasksFetch = fetchListingTasksForAgent()
            async let strayTasksFetch = fetchStrayTasksForAgent()

            // Await all results
            let (fetchedRealtor, fetchedListings, fetchedListingTasks, fetchedStrayTasks) = try await (
                realtorFetch,
                listingsFetch,
                listingTasksFetch,
                strayTasksFetch
            )

            self.realtor = fetchedRealtor
            self.listings = fetchedListings
            self.listingTasks = fetchedListingTasks
            self.strayTasks = fetchedStrayTasks

            Logger.database.info(
                "Fetched agent data: \(fetchedListings.count) listings, \(fetchedListingTasks.count) listing tasks, \(fetchedStrayTasks.count) stray tasks"
            )
        } catch {
            Logger.database.error("Failed to fetch agent data: \(error.localizedDescription)")
            errorMessage = "Failed to load agent data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() async {
        await fetchAgentData()
    }

    // MARK: - Private Helpers

    private func fetchListingsForAgent() async throws -> [ListingWithActivities] {
        // TODO: Implement when ListingRepositoryClient is available
        // For now return empty array
        Logger.database.info("Fetching listings for agent \(self.realtorId)")
        return []
    }

    private func fetchListingTasksForAgent() async throws -> [ListingTaskWithDetails] {
        Logger.database.info("Fetching listing tasks for agent \(self.realtorId)")
        let tasks = try await taskRepository.fetchListingTasksByRealtor(realtorId)
        return tasks
    }

    private func fetchStrayTasksForAgent() async throws -> [StrayTaskWithMessages] {
        Logger.database.info("Fetching stray tasks for agent \(self.realtorId)")
        let tasks = try await taskRepository.fetchStrayTasksByRealtor(realtorId)
        return tasks
    }

    // MARK: - UI Actions

    func toggleListingExpansion(for listingId: String) {
        if expandedListingId == listingId {
            expandedListingId = nil
        } else {
            expandedListingId = listingId
            expandedTaskId = nil  // Collapse any expanded task
        }
    }

    func toggleTaskExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
            expandedListingId = nil  // Collapse any expanded listing
        }
    }

    // MARK: - Task Actions

    func claimStrayTask(_ task: StrayTask) async {
        Logger.tasks.info("Claiming stray task: \(task.id)")
        // TODO: Implement claim functionality
    }

    func deleteStrayTask(_ task: StrayTask) async {
        Logger.tasks.info("Deleting stray task: \(task.id)")
        // TODO: Implement delete functionality
    }

    func claimListingTask(_ task: ListingTask) async {
        Logger.tasks.info("Claiming listing task: \(task.id)")
        // TODO: Implement claim functionality
    }

    func deleteListingTask(_ task: ListingTask) async {
        Logger.tasks.info("Deleting listing task: \(task.id)")
        // TODO: Implement delete functionality
    }
}
