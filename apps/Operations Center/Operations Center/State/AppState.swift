//
//  AppState.swift
//  Operations Center
//
//  App-level state management with permanent real-time sync
//  Single source of truth for all task data
//

import Foundation
import Supabase
import Dependencies
import OperationsCenterKit

@Observable
@MainActor
final class AppState {
    // MARK: - State

    var allTasks: [ListingTask] = []
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.supabaseClient) var supabaseClient

    @ObservationIgnored
    @Dependency(\.taskRepository) var taskRepository

    @ObservationIgnored
    private var realtimeSubscription: Task<Void, Never>?

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    /// Skip network operations in preview/test mode
    /// Reference: swift-dependencies/Testing.md - conditional execution pattern
    @ObservationIgnored
    private var shouldPerformNetworkOperations: Bool {
        AppConfig.Environment.current != .preview
    }

    // MARK: - Computed Properties

    /// Tasks that are unclaimed (Inbox)
    var inboxTasks: [ListingTask] {
        allTasks.filter { $0.assignedStaffId == nil }
    }

    /// Tasks assigned to the current user
    var myTasks: [ListingTask] {
        guard let userId = currentUser?.id else { return [] }
        return allTasks.filter { $0.assignedStaffId == userId.uuidString }
    }

    // MARK: - Initialization

    init() {
        // Load cached data immediately for instant UI
        loadCachedData()
        // Network work deferred to startup() - called after app launches
    }

    // MARK: - Startup

    /// Start async operations after app launch
    /// Call this from .task modifier in RootView
    /// Reference: swift-dependencies/WhatAreDependencies.md - guarded async operations
    func startup() async {
        guard shouldPerformNetworkOperations else {
            print("⚠️ Preview mode: Skipping network operations")
            loadPreviewData()
            return
        }

        await setupAuthStateListener()
        await fetchTasks()
        await setupPermanentRealtimeSync()
    }

    deinit {
        realtimeSubscription?.cancel()
        authStateTask?.cancel()
    }

    /// Load preview data synchronously - no async, no network
    /// Reference: swift-dependencies/LivePreviewTest.md - preview data patterns
    private func loadPreviewData() {
        allTasks = [
            ListingTask.mock1,
            ListingTask.mock2,
            ListingTask.mock3
        ]
        currentUser = nil  // No auth in preview
        isLoading = false
        errorMessage = nil
    }

    // MARK: - Authentication

    private func setupAuthStateListener() async {
        guard shouldPerformNetworkOperations else { return }

        // Listen for auth state changes
        authStateTask = Task {
            for await state in supabaseClient.auth.authStateChanges {
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

    func fetchTasks() async {
        guard shouldPerformNetworkOperations else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Use TaskRepositoryClient which respects preview/live context
            let taskData = try await taskRepository.fetchListingTasks()
            allTasks = taskData.map { $0.0 }  // Extract just the tasks

            // Save to cache
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Real-time Sync

    private func setupPermanentRealtimeSync() async {
        guard shouldPerformNetworkOperations else { return }

        // Cancel any existing subscription
        realtimeSubscription?.cancel()

        let channel = supabaseClient.realtimeV2.channel("all_tasks")

        realtimeSubscription = Task {
            do {
                // Setup listener BEFORE subscribing
                let listenerTask = Task {
                    for await change in channel.postgresChange(AnyAction.self, table: "listing_tasks") {
                        await handleRealtimeChange(change)
                    }
                }

                // Now subscribe to start receiving events
                try await channel.subscribeWithError()

                // Keep listener running
                await listenerTask.value
            } catch {
                await MainActor.run {
                    errorMessage = "Realtime subscription error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func handleRealtimeChange(_ change: AnyAction) async {
        // Refresh entire list on any change
        // This ensures all views stay in sync
        do {
            // Use TaskRepositoryClient which respects preview/live context
            let taskData = try await taskRepository.fetchListingTasks()
            allTasks = taskData.map { $0.0 }  // Extract just the tasks

            // Save to cache
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Task Actions

    func claimTask(_ task: ListingTask) async {
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

    func deleteTask(_ task: ListingTask) async {
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

    func refresh() async {
        await fetchTasks()
    }
}
