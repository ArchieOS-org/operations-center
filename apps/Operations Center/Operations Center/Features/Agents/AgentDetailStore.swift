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
    private(set) var activities: [ActivityWithDetails] = []
    private(set) var tasks: [TaskWithMessages] = []

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
            async let activitiesFetch = fetchActivitiesForAgent()
            async let tasksFetch = fetchTasksForAgent()

            // Await all results
            let (fetchedRealtor, fetchedListings, fetchedActivities, fetchedTasks) = try await (
                realtorFetch,
                listingsFetch,
                activitiesFetch,
                tasksFetch
            )

            self.realtor = fetchedRealtor
            self.listings = fetchedListings
            self.activities = fetchedActivities
            self.tasks = fetchedTasks

            Logger.database.info(
                "Fetched agent data: \(fetchedListings.count) listings, \(fetchedActivities.count) activities, \(fetchedTasks.count) agent tasks"
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
        // NOTE: Placeholder until ListingRepositoryClient is available.
        // For now, return an empty array.
        Logger.database.info("Fetching listings for agent \(self.realtorId)")
        return []
    }

    private func fetchActivitiesForAgent() async throws -> [ActivityWithDetails] {
        Logger.database.info("Fetching activities for agent \(self.realtorId)")
        let tasks = try await taskRepository.fetchActivitiesByRealtor(realtorId)
        return tasks
    }

    private func fetchTasksForAgent() async throws -> [TaskWithMessages] {
        Logger.database.info("Fetching agent tasks for agent \(self.realtorId)")
        let tasks = try await taskRepository.fetchTasksByRealtor(realtorId)
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

    func claimTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            let currentUserId = "current-staff-id"
            _ = try await taskRepository.claimTask(task.id, currentUserId)

            Logger.tasks.info("Claimed agent task: \(task.id)")

            // Refresh to get updated data
            await fetchAgentData()
        } catch {
            Logger.tasks.error("Failed to claim agent task: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    func deleteTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            let currentUserId = "current-staff-id"
            try await taskRepository.deleteTask(task.id, currentUserId)

            Logger.tasks.info("Deleted agent task: \(task.id)")

            // Refresh to get updated data
            await fetchAgentData()
        } catch {
            Logger.tasks.error("Failed to delete agent task: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    func claimActivity(_ task: Activity) async {
        errorMessage = nil

        do {
            let currentUserId = "current-staff-id"
            _ = try await taskRepository.claimActivity(task.id, currentUserId)

            Logger.tasks.info("Claimed activity: \(task.id)")

            // Refresh to get updated data
            await fetchAgentData()
        } catch {
            Logger.tasks.error("Failed to claim activity: \(error.localizedDescription)")
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    func deleteActivity(_ task: Activity) async {
        errorMessage = nil

        do {
            let currentUserId = "current-staff-id"
            try await taskRepository.deleteActivity(task.id, currentUserId)

            Logger.tasks.info("Deleted activity: \(task.id)")

            // Refresh to get updated data
            await fetchAgentData()
        } catch {
            Logger.tasks.error("Failed to delete activity: \(error.localizedDescription)")
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }
}
