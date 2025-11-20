//
//  AgentDetailStore.swift
//  Operations Center
//
//  Agent Detail screen store - manages all work for a specific agent
//  Per TASK_MANAGEMENT_SPEC.md lines 272-283
//

import Dependencies
import Foundation
import SwiftUI
import OSLog
import OperationsCenterKit
import Supabase

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

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    /// Supabase client for realtime subscriptions
    @ObservationIgnored
    private let supabase: SupabaseClient

    /// Realtime subscription tasks
    @ObservationIgnored
    private var staffRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var agentTasksRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var activitiesRealtimeTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        realtorId: String,
        realtorRepository: RealtorRepositoryClient,
        taskRepository: TaskRepositoryClient,
        supabase: SupabaseClient
    ) {
        self.realtorId = realtorId
        self.realtorRepository = realtorRepository
        self.taskRepository = taskRepository
        self.supabase = supabase
    }

    deinit {
        staffRealtimeTask?.cancel()
        agentTasksRealtimeTask?.cancel()
        activitiesRealtimeTask?.cancel()
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
                """
                Fetched agent data: \(fetchedListings.count) listings, \
                \(fetchedActivities.count) activities, \(fetchedTasks.count) agent tasks
                """
            )

            // Start realtime subscriptions AFTER initial load
            await setupRealtimeSubscriptions()
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
            _ = try await taskRepository.claimTask(task.id, await authClient.currentUserId())

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
            try await taskRepository.deleteTask(task.id, await authClient.currentUserId())

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
            _ = try await taskRepository.claimActivity(task.id, await authClient.currentUserId())

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
            try await taskRepository.deleteActivity(task.id, await authClient.currentUserId())

            Logger.tasks.info("Deleted activity: \(task.id)")

            // Refresh to get updated data
            await fetchAgentData()
        } catch {
            Logger.tasks.error("Failed to delete activity: \(error.localizedDescription)")
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Realtime Subscriptions

    /// Setup all realtime subscriptions
    private func setupRealtimeSubscriptions() async {
        await setupStaffRealtime()
        await setupAgentTasksRealtime()
        await setupActivitiesRealtime()
    }

    /// Setup realtime subscription for staff (realtor profile)
    private func setupStaffRealtime() async {
        staffRealtimeTask?.cancel()

        let channel = supabase.realtimeV2.channel("agent_detail_\(realtorId)_staff")

        staffRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = channel.postgresChange(AnyAction.self, table: "staff")

                // Now subscribe to start receiving events
                try await channel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleStaffChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Agent detail staff realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime staff changes - simple refresh strategy
    private func handleStaffChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Staff change detected, refreshing...")

        // Simple approach: re-fetch everything
        await fetchAgentData()
    }

    /// Setup realtime subscription for agent tasks
    private func setupAgentTasksRealtime() async {
        agentTasksRealtimeTask?.cancel()

        let channel = supabase.realtimeV2.channel("agent_detail_\(realtorId)_tasks")

        agentTasksRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing
                let stream = channel.postgresChange(AnyAction.self, table: "agent_tasks")

                // Now subscribe to start receiving events
                try await channel.subscribeWithError()

                // Listen for changes
                for await change in stream {
                    await self.handleAgentTasksChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.tasks.error("Agent detail tasks realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime agent tasks changes - simple refresh strategy
    private func handleAgentTasksChange(_ change: AnyAction) async {
        Logger.tasks.info("Realtime: Agent tasks change detected, refreshing...")

        // Simple approach: re-fetch everything
        await fetchAgentData()
    }

    /// Setup realtime subscription for activities
    private func setupActivitiesRealtime() async {
        activitiesRealtimeTask?.cancel()

        let channel = supabase.realtimeV2.channel("agent_detail_\(realtorId)_activities")

        activitiesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing
                let stream = channel.postgresChange(AnyAction.self, table: "activities")

                // Now subscribe to start receiving events
                try await channel.subscribeWithError()

                // Listen for changes
                for await change in stream {
                    await self.handleActivitiesChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.tasks.error("Agent detail activities realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime activities changes - simple refresh strategy
    private func handleActivitiesChange(_ change: AnyAction) async {
        Logger.tasks.info("Realtime: Activities change detected, refreshing...")

        // Simple approach: re-fetch everything
        await fetchAgentData()
    }
}
