//
//  BackgroundSyncManager.swift
//  Operations Center
//
//  Created by Background Sync Task on 2025-11-20.
//

@preconcurrency import BackgroundTasks
import Foundation

/// Manages background app refresh tasks to keep local cache fresh when app is backgrounded.
///
/// Responsibilities:
/// - Handle BGAppRefreshTask lifecycle (register, schedule, execute)
/// - Perform lightweight data sync from Supabase → SwiftData
/// - Respect 30-second BGAppRefreshTask time budget
/// - Cancel work gracefully on expiration
///
/// Phase 2 Constraints:
/// - Pull only (no outbound writes)
/// - Use existing repository fetch methods
/// - No changes to isDirty or write queue
final class BackgroundSyncManager {
    @MainActor static let shared = BackgroundSyncManager()

    // MARK: - Task Identifier

    /// Background task identifier registered in Info.plist BGTaskSchedulerPermittedIdentifiers
    nonisolated static let refreshTaskIdentifier = "com.conductor.operationscenter.refresh"

    // MARK: - Dependencies (Injected from App Setup)

    /// Local SwiftData database for persistence
    @MainActor var localDatabase: LocalDatabase!

    /// Repository for listing operations
    @MainActor var listingRepository: ListingRepositoryClient!

    /// Repository for activity/task operations
    @MainActor var taskRepository: TaskRepositoryClient!

    /// Repository for listing note operations
    @MainActor var noteRepository: ListingNoteRepositoryClient!

    /// Repository for realtor operations
    @MainActor var realtorRepository: RealtorRepositoryClient!

    /// Repository for staff operations
    @MainActor var staffRepository: StaffRepositoryClient!

    // MARK: - Initialization

    private init() {}

    // MARK: - Background Task Handler

    /// Handles BGAppRefreshTask execution
    ///
    /// Called by iOS when background refresh opportunity arrives.
    /// Must complete within 30 seconds or task will be terminated.
    ///
    /// - Parameter task: The background app refresh task to handle
    nonisolated func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh immediately (Apple best practice)
        Task { @MainActor in
            scheduleAppRefresh()
        }

        // Create operation queue for work cancellation
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        // Set expiration handler BEFORE starting work
        // Fires ~5 seconds before 30-second limit
        task.expirationHandler = {
            // Cancel any pending work to avoid corruption
            queue.cancelAllOperations()
            print("⏰ [BackgroundSync] Task expired - cancelling operations")
        }

        // Perform sync work
        queue.addOperation {
            Task { @MainActor in
                do {
                    try await self.performLightweightSync()
                    task.setTaskCompleted(success: true)
                    print("✅ [BackgroundSync] Completed successfully")
                } catch {
                    task.setTaskCompleted(success: false)
                    print("❌ [BackgroundSync] Failed: \(error)")
                }
            }
        }
    }

    // MARK: - Scheduling

    /// Schedules the next background app refresh
    ///
    /// Submits a BGAppRefreshTaskRequest to iOS.
    /// System decides when to actually run based on usage patterns.
    /// Request replaces any previously scheduled refresh task.
    @MainActor func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)

        // Set earliest begin date (15 minutes recommended minimum)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 [BackgroundSync] Scheduled refresh (earliest: 15 min)")
        } catch {
            // Log but don't crash - scheduling is best-effort
            print("⚠️ [BackgroundSync] Could not schedule: \(error)")
        }
    }

    // MARK: - Sync Logic

    /// Performs full pull-only sync from Supabase
    ///
    /// Fetches all critical data to keep the app's local cache fresh:
    /// - Category A (SwiftData-backed): Listings, Activities (with listings join)
    /// - Category B (Network-only): Realtors, Staff
    ///
    /// Constraints:
    /// - Only fetches data (no writes)
    /// - Uses existing repository methods
    /// - Must complete in <30 seconds (BGAppRefreshTask budget)
    /// - Parallel fetches to maximize efficiency
    /// - Updates SwiftData where applicable, network-only caches otherwise
    ///
    /// Intentionally skipped:
    /// - ListingNotes: Fetched lazily per-listing to avoid N+1 queries
    /// - ListingAcknowledgments: User-specific, fetched on-demand
    /// - AgentTasks: Deprecated in favor of Activities
    @MainActor func performFullSync() async throws {
        print("🔄 [BackgroundSync] Starting full sync...")

        // Phase 1: Parallel fetches (10-15 seconds)
        // Use async let for true concurrency - all queries run simultaneously
        async let listings = listingRepository.fetchListings()
        async let activities = taskRepository.fetchActivities()  // Includes listings via join
        async let realtors = realtorRepository.fetchRealtors()
        async let staff = staffRepository.listActive()

        // Await all fetches - each repository handles Supabase → local persistence
        _ = try await (listings, activities, realtors, staff)

        print("  ↳ Listings synced")
        print("  ↳ Activities synced (with associated listings)")
        print("  ↳ Realtors synced")
        print("  ↳ Staff synced")
        print("✨ [BackgroundSync] Full sync complete")
    }

    /// Performs lightweight pull-only sync from Supabase (legacy - now calls performFullSync)
    ///
    /// Phase 2 Constraints:
    /// - Only fetches data (no writes)
    /// - Uses existing repository methods
    /// - Must complete in <30 seconds
    /// - Updates SwiftData cache for next foreground session
    ///
    /// Current Implementation:
    /// - Delegates to performFullSync() for comprehensive data refresh
    /// - Kept for API compatibility; may be deprecated in future
    @MainActor private func performLightweightSync() async throws {
        try await performFullSync()
    }
}
