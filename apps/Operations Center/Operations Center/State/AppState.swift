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
    var currentUser: Supabase.User?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let supabase: SupabaseClient
    private let taskRepository: TaskRepositoryClient
    private let localDatabase: LocalDatabase

    /// Singleton coalescers for request deduplication
    /// Shared across all stores to prevent duplicate network calls
    @ObservationIgnored
    let activityCoalescer = ActivityFetchCoalescer()

    @ObservationIgnored
    let listingCoalescer = ListingFetchCoalescer()

    @ObservationIgnored
    let noteCoalescer = NoteFetchCoalescer()

    @ObservationIgnored
    let taskCoalescer = TaskFetchCoalescer()

    @ObservationIgnored
    private var realtimeSubscription: Task<Void, Never>?

    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?

    @ObservationIgnored
    private var taskRefreshTask: Task<Void, Error>?

    // Create channel once as property (prevents "postgresChange after joining" error)
    @ObservationIgnored
    private lazy var tasksChannel = supabase.realtimeV2.channel("all_tasks")

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
    /// For production: AppState(supabase: supabase, taskRepository: .live, localDatabase: SwiftDataLocalDatabase)
    /// For previews: AppState(supabase: .preview, taskRepository: .preview, localDatabase: PreviewLocalDatabase())
    init(
        supabase: SupabaseClient,
        taskRepository: TaskRepositoryClient,
        localDatabase: LocalDatabase
    ) {
        self.supabase = supabase
        self.taskRepository = taskRepository
        self.localDatabase = localDatabase
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
        // Unsubscribe channel before canceling tasks
        Task.detached { [weak self] in
            guard let self else { return }
            await tasksChannel.unsubscribe()
        }
        realtimeSubscription?.cancel()
        authStateTask?.cancel()
    }

    // MARK: - Authentication

    private func setupAuthStateListener() async {
        // Listen for auth state changes using structured concurrency
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await state in self.supabase.auth.authStateChanges
                where [.initialSession, .signedIn, .signedOut].contains(state.event) {
                self.currentUser = state.session?.user

                // Refresh tasks when auth state changes
                if state.session != nil {
                    // Cancel any pending refresh to avoid race condition
                    self.taskRefreshTask?.cancel()
                    self.taskRefreshTask = Task {
                        await self.fetchTasks()
                    }
                } else {
                    // User logged out - cancel pending refresh
                    self.taskRefreshTask?.cancel()
                    self.taskRefreshTask = nil
                }
            }
        }
    }

    // MARK: - Data Loading

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Use TaskRepositoryClient (production or preview based on init)
            Logger.database.info("AppState.fetchTasks() starting...")
            let taskData = try await taskRepository.fetchActivities()
            self.allTasks = taskData.map(\.task)  // Extract just the activities
            Logger.database.info("AppState now has \(self.allTasks.count) tasks")

            // Save to cache
            saveCachedData()
        } catch {
            Logger.database.error("❌ fetchTasks failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
        Logger.database.info("AppState.fetchTasks() completed")
    }

    // MARK: - Real-time Sync

    private func setupPermanentRealtimeSync() async {
        // Cancel any existing subscription
        realtimeSubscription?.cancel()

        // Reuse the channel property (prevents "postgresChange after joining" error)
        realtimeSubscription = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = tasksChannel.postgresChange(AnyAction.self, table: "activities")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await tasksChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleRealtimeChange(change)
                }
            } catch is CancellationError {
                // Normal cancellation, no error
                return
            } catch {
                self.errorMessage = "Realtime subscription error: \(error.localizedDescription)"
            }
        }
    }

    private func handleRealtimeChange(_ change: AnyAction) async {
        // Refresh entire list on any change
        // This ensures all views stay in sync
        Logger.database.info("Handling realtime change...")
        do {
            let taskData = try await taskRepository.fetchActivities()
            self.allTasks = taskData.map(\.task)  // Extract just the activities
            Logger.database.info("Updated \(self.allTasks.count) tasks from realtime change")

            // Save to cache
            saveCachedData()
        } catch {
            Logger.database.error("❌ Realtime change handler failed: \(error.localizedDescription)")
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
        // Migrate from old UserDefaults cache if needed
        migrateFromUserDefaultsIfNeeded()

        // Load from SwiftData local database
        do {
            allTasks = try localDatabase.fetchActivities()
            Logger.database.info("Loaded \(self.allTasks.count) tasks from local database")
        } catch {
            Logger.database.error("Failed to load cached tasks from local database: \(error.localizedDescription)")
        }
    }

    private func saveCachedData() {
        // Save to SwiftData local database
        do {
            try localDatabase.upsertActivities(allTasks)
            Logger.database.debug("Saved \(self.allTasks.count) tasks to local database")
        } catch {
            Logger.database.error("Failed to save tasks to local database: \(error.localizedDescription)")
        }
    }

    /// One-time migration from UserDefaults to SwiftData
    /// Runs once on first launch with SwiftData enabled
    private func migrateFromUserDefaultsIfNeeded() {
        let migrationKey = "did_migrate_to_swiftdata"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // Check if old UserDefaults cache exists
        if let data = UserDefaults.standard.data(forKey: "cached_tasks"),
           let tasks = try? JSONDecoder().decode([Activity].self, from: data) {
            Logger.database.info("Migrating \(tasks.count) tasks from UserDefaults to SwiftData")

            // Import into SwiftData
            do {
                try localDatabase.upsertActivities(tasks)
                Logger.database.info("Migration successful")

                // Clear old cache
                UserDefaults.standard.removeObject(forKey: "cached_tasks")
            } catch {
                Logger.database.error("Migration failed: \(error.localizedDescription)")
            }
        }

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    // MARK: - Public Refresh

    func refresh() async {
        await fetchTasks()
    }
}
