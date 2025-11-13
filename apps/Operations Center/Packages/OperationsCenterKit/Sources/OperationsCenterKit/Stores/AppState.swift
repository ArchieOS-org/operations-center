//
//  AppState.swift
//  OperationsCenterKit
//
//  App-level state management with permanent real-time sync
//  Single source of truth for all task data
//

import Foundation
import Supabase
import Dependencies

@Observable
public final class AppState {
    // MARK: - State

    public var allTasks: [ListingTask] = []
    public var currentUser: User?
    public var isLoading = false
    public var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.supabaseClient) var supabaseClient

    @ObservationIgnored
    private var realtimeSubscription: Task<Void, Never>?

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Tasks that are unclaimed (Inbox)
    public var inboxTasks: [ListingTask] {
        allTasks.filter { $0.assignedStaffId == nil }
    }

    /// Tasks assigned to the current user
    public var myTasks: [ListingTask] {
        guard let userId = currentUser?.id else { return [] }
        return allTasks.filter { $0.assignedStaffId == userId.uuidString }
    }

    // MARK: - Initialization

    public init() {
        // Load cached data immediately for instant UI
        loadCachedData()

        // Set up permanent subscriptions
        Task { @MainActor in
            await setupAuthStateListener()
            await fetchTasks()
            await setupPermanentRealtimeSync()
        }
    }

    deinit {
        realtimeSubscription?.cancel()
        authStateTask?.cancel()
    }

    // MARK: - Authentication

    @MainActor
    private func setupAuthStateListener() async {
        // Listen for auth state changes
        authStateTask = Task {
            for await state in await supabaseClient.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    currentUser = state.session?.user

                    // Refresh tasks when auth state changes
                    if state.session != nil {
                        await fetchTasks()
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    @MainActor
    public func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            allTasks = try await supabaseClient
                .from("listing_tasks")
                .select()
                .order("priority", ascending: false)
                .order("created_at", ascending: true)
                .execute()
                .value

            // Save to cache
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Real-time Sync

    @MainActor
    private func setupPermanentRealtimeSync() async {
        // Cancel any existing subscription
        realtimeSubscription?.cancel()

        let channel = await supabaseClient.realtimeV2.channel("all_tasks")

        realtimeSubscription = Task {
            await channel.subscribe()

            // Listen forever - subscription never tears down
            for await change in channel.postgresChange(AnyAction.self, table: "listing_tasks") {
                await handleRealtimeChange(change)
            }
        }
    }

    @MainActor
    private func handleRealtimeChange(_ change: AnyAction) async {
        // Refresh entire list on any change
        // This ensures all views stay in sync
        do {
            allTasks = try await supabaseClient
                .from("listing_tasks")
                .select()
                .order("priority", ascending: false)
                .order("created_at", ascending: true)
                .execute()
                .value

            // Save to cache
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Task Actions

    @MainActor
    public func claimTask(_ task: ListingTask) async {
        errorMessage = nil

        guard let userId = currentUser?.id else {
            errorMessage = "Must be logged in to claim tasks"
            return
        }

        do {
            let _: ListingTask = try await supabaseClient
                .from("listing_tasks")
                .update([
                    "assigned_staff_id": userId.uuidString,
                    "claimed_at": ISO8601DateFormatter().string(from: Date()),
                    "status": "CLAIMED"
                ])
                .eq("task_id", value: task.id)
                .single()
                .execute()
                .value

            // Real-time subscription will handle the update
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func deleteTask(_ task: ListingTask) async {
        errorMessage = nil

        do {
            try await supabaseClient
                .from("listing_tasks")
                .delete()
                .eq("task_id", value: task.id)
                .execute()

            // Real-time subscription will handle the update
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Local Persistence

    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "cached_tasks"),
           let tasks = try? JSONDecoder().decode([ListingTask].self, from: data) {
            allTasks = tasks
        }
    }

    private func saveCachedData() {
        if let data = try? JSONEncoder().encode(allTasks) {
            UserDefaults.standard.set(data, forKey: "cached_tasks")
        }
    }

    // MARK: - Public Refresh

    @MainActor
    public func refresh() async {
        await fetchTasks()
    }
}
