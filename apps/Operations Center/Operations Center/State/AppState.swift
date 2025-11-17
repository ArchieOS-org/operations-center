//
//  AppState.swift
//  Operations Center
//
//  App-level state management with permanent real-time sync
//  Single source of truth for all task data
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

@Observable
@MainActor
final class AppState {
    // MARK: - State

    var allTasks: [Activity] = []
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let supabase: SupabaseClient
    private let taskRepository: TaskRepositoryClient

    @ObservationIgnored
    private var realtimeSubscription: Task<Void, Never>?

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Tasks that are unclaimed (Inbox)
    var inboxTasks: [Activity] {
        allTasks.filter { $0.assignedStaffId == nil }
    }

    /// Tasks assigned to the current user
    var myTasks: [Activity] {
        guard let userId = currentUser?.id else { return [] }
        return allTasks.filter { $0.assignedStaffId == userId.uuidString }
    }

    // MARK: - Initialization

    /// Initialize AppState with dependency injection
    /// For production: AppState(supabase: supabase, taskRepository: .live)
    /// For previews: AppState(supabase: .preview, taskRepository: .preview)
    init(
        supabase: SupabaseClient,
        taskRepository: TaskRepositoryClient
    ) {
        self.supabase = supabase
        self.taskRepository = taskRepository
        // NO synchronous work here - prevents MainActor blocking
    }

    // MARK: - Startup

    /// Start async operations after app launch
    /// Call this from .task modifier in RootView
    func startup() async {
        // Load cached data first for instant UI
        loadCachedData()

        // Setup async operations
        await setupAuthStateListener()
        await fetchTasks()
        await setupPermanentRealtimeSync()
    }

    deinit {
        realtimeSubscription?.cancel()
        authStateTask?.cancel()
    }

    // MARK: - Authentication

    private func setupAuthStateListener() async {
        // Listen for auth state changes
        authStateTask = Task {
            for await state in supabase.auth.authStateChanges
                where [.initialSession, .signedIn, .signedOut].contains(state.event) {
                currentUser = state.session?.user

                // Refresh tasks when auth state changes
                if state.session != nil {
                    await fetchTasks()
                }
            }
        }
    }

    // MARK: - Data Loading

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        Logger.database.info("AppState.fetchTasks() starting...")

        do {
            // Use TaskRepositoryClient (production or preview based on init)
            Logger.database.info("Calling taskRepository.fetchActivities()...")
            let taskData = try await taskRepository.fetchActivities()
            Logger.database.info("Received \(taskData.count) activities from repository")

            allTasks = taskData.map(\.task)  // Extract just the activities
            Logger.database.info("AppState now has \(self.allTasks.count) tasks")

            // Save to cache
            saveCachedData()
        } catch {
            Logger.database.error("❌ fetchTasks failed: \(error.localizedDescription)")
            Logger.database.error("Error details: \(String(describing: error))")
            errorMessage = error.localizedDescription
        }

        isLoading = false
        Logger.database.info("AppState.fetchTasks() completed. isLoading=false")
    }

    // MARK: - Real-time Sync

    private func setupPermanentRealtimeSync() async {
        // Cancel any existing subscription
        realtimeSubscription?.cancel()

        let channel = supabase.realtimeV2.channel("all_tasks")

        realtimeSubscription = Task {
            do {
                // Setup listener BEFORE subscribing
                let listenerTask = Task {
                    for await change in channel.postgresChange(AnyAction.self, table: "activities") {
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
            let taskData = try await taskRepository.fetchActivities()
            allTasks = taskData.map(\.task)  // Extract just the activities

            // Save to cache
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Task Actions

    func claimTask(_ task: Activity) async {
        errorMessage = nil

        guard let userId = currentUser?.id else {
            errorMessage = "Must be logged in to claim tasks"
            return
        }

        do {
            let _: Activity = try await supabase
                .from("activities")
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

    func deleteTask(_ task: Activity) async {
        errorMessage = nil

        do {
            try await supabase
                .from("activities")
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
           let tasks = try? JSONDecoder().decode([Activity].self, from: data) {
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
