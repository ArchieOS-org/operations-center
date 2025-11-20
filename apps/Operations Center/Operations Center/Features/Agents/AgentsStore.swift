//
//  AgentsStore.swift
//  Operations Center
//
//  Store managing the list of agents/realtors
//  Per TASK_MANAGEMENT_SPEC.md lines 260-270
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

/// Store managing the list of agents/realtors
@Observable
@MainActor
final class AgentsStore {
    // MARK: - Observable State

    private(set) var realtors: [Realtor] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let repository: RealtorRepositoryClient

    /// Supabase client for realtime subscriptions
    @ObservationIgnored
    private let supabase: SupabaseClient

    /// Realtime channel (created once, prevents "postgresChange after joining" error)
    @ObservationIgnored
    private lazy var realtorsChannel = supabase.realtimeV2.channel("agents_staff")

    /// Realtime subscription task
    @ObservationIgnored
    private var realtorsRealtimeTask: Task<Void, Never>?

    // MARK: - Initialization

    /// For production: AgentsStore(repository: .live, supabase: supabase)
    /// For previews: AgentsStore(repository: .preview, supabase: supabase)
    init(repository: RealtorRepositoryClient, supabase: SupabaseClient) {
        self.repository = repository
        self.supabase = supabase
    }

    deinit {
        Task.detached { [weak self] in
            guard let self else { return }
            await realtorsChannel.unsubscribe()
        }
        realtorsRealtimeTask?.cancel()
    }

    // MARK: - Actions

    /// Fetch all active realtors
    func fetchRealtors() async {
        isLoading = true
        errorMessage = nil

        do {
            realtors = try await repository.fetchRealtors()
            Logger.database.info("Fetched \(self.realtors.count) realtors")

            // Start realtime subscriptions AFTER initial load
            await setupRealtorsRealtime()
        } catch {
            Logger.database.error("Failed to fetch realtors: \(error.localizedDescription)")
            errorMessage = "Failed to load agents: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh the list
    func refresh() async {
        await fetchRealtors()
    }

    // MARK: - Realtime Subscriptions

    /// Setup realtime subscription for staff (realtors)
    private func setupRealtorsRealtime() async {
        realtorsRealtimeTask?.cancel()

        realtorsRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = realtorsChannel.postgresChange(AnyAction.self, table: "staff")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await realtorsChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleRealtorsChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Realtors realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime staff changes - simple refresh strategy
    private func handleRealtorsChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Staff change detected, refreshing...")

        // Simple approach: re-fetch everything
        await fetchRealtors()
    }
}
