//
//  AllListingsStore.swift
//  Operations Center
//
//  All Listings store - manages all listings system-wide
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

@Observable
@MainActor
final class AllListingsStore {
    // MARK: - Properties

    /// Defer filtering updates during batch mutations
    private var isDeferringUpdates = false

    /// All listings
    private(set) var listings: [Listing] = [] {
        didSet {
            guard !isDeferringUpdates else { return }
            updateFilteredListings()
        }
    }

    /// Category filter selection (nil = "All")
    var selectedCategory: TaskCategory? {
        didSet {
            guard !isDeferringUpdates else { return }
            updateFilteredListings()
        }
    }

    /// Mapping of listing ID to categories of all tasks for that listing
    private var listingCategories: [String: Set<TaskCategory?>] = [:] {
        didSet {
            guard !isDeferringUpdates else { return }
            updateFilteredListings()
        }
    }

    /// Cached filtered listings - updated when listings or category changes
    /// Performance: Filter runs once per change, not 60x/second
    private(set) var filteredListings: [Listing] = []

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repository for data access
    private let listingRepository: ListingRepositoryClient
    private let taskRepository: TaskRepositoryClient

    /// Coalescers for request deduplication
    private let listingCoalescer: ListingFetchCoalescer
    private let activityCoalescer: ActivityFetchCoalescer

    /// Supabase client for realtime subscriptions
    @ObservationIgnored
    private let supabase: SupabaseClient

    /// Realtime channels (created once, prevents "postgresChange after joining" error)
    @ObservationIgnored
    private lazy var listingsChannel = supabase.realtimeV2.channel("all_listings")

    @ObservationIgnored
    private lazy var activitiesChannel = supabase.realtimeV2.channel("all_listings_activities")

    /// Realtime subscription tasks
    @ObservationIgnored
    private var listingsRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var activitiesRealtimeTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        listingRepository: ListingRepositoryClient,
        taskRepository: TaskRepositoryClient,
        supabase: SupabaseClient,
        listingCoalescer: ListingFetchCoalescer,
        activityCoalescer: ActivityFetchCoalescer
    ) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
        self.supabase = supabase
        self.listingCoalescer = listingCoalescer
        self.activityCoalescer = activityCoalescer
    }

    deinit {
        // Unsubscribe channels before canceling tasks
        Task.detached { [weak self] in
            guard let self else { return }
            await listingsChannel.unsubscribe()
            await activitiesChannel.unsubscribe()
        }
        listingsRealtimeTask?.cancel()
        activitiesRealtimeTask?.cancel()
    }

    // MARK: - Preview Support

    /// Preview factory for SwiftUI previews
    @MainActor
    static func makePreview(supabase: SupabaseClient) -> AllListingsStore {
        AllListingsStore(
            listingRepository: .preview,
            taskRepository: .preview,
            supabase: supabase,
            listingCoalescer: ListingFetchCoalescer(),
            activityCoalescer: ActivityFetchCoalescer()
        )
    }

    // MARK: - Private Methods

    /// Update cached filtered listings when data or filter changes
    /// Performance optimization: Filter runs once per change, not on every SwiftUI redraw
    private func updateFilteredListings() {
        if selectedCategory == nil {
            filteredListings = listings
        } else {
            filteredListings = listings.filter { listing in
                listingCategories[listing.id]?.contains(selectedCategory) ?? false
            }
        }
    }

    // MARK: - Actions

    /// Fetch all listings
    func fetchAllListings() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch both listings and activities in parallel using coalescers
            async let listingsResult = listingCoalescer.fetch(using: listingRepository)
            async let activitiesResult = activityCoalescer.fetch(using: taskRepository)

            let (allListings, allActivities) = try await (listingsResult, activitiesResult)

            // Build category mapping from activities
            var categoryMapping: [String: Set<TaskCategory?>] = [:]
            for activityWithDetails in allActivities {
                let listingId = activityWithDetails.task.listingId

                if categoryMapping[listingId] == nil {
                    categoryMapping[listingId] = Set()
                }
                categoryMapping[listingId]?.insert(activityWithDetails.task.taskCategory)
            }

            // Batch update: defer filtering until both properties updated
            isDeferringUpdates = true
            listings = allListings
            listingCategories = categoryMapping
            isDeferringUpdates = false

            // Trigger single filter update with complete data
            updateFilteredListings()

            // Start realtime subscriptions AFTER initial load
            await setupRealtimeSubscriptions()
        } catch {
            Logger.database.error("Failed to fetch all listings: \(error.localizedDescription)")
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh listings
    func refresh() async {
        await fetchAllListings()
    }

    // MARK: - Realtime Subscriptions

    /// Setup all realtime subscriptions
    private func setupRealtimeSubscriptions() async {
        await setupListingsRealtime()
        await setupActivitiesRealtime()
    }

    /// Setup realtime subscription for all listings
    private func setupListingsRealtime() async {
        listingsRealtimeTask?.cancel()

        // Reuse the channel property (prevents "postgresChange after joining" error)
        listingsRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = listingsChannel.postgresChange(AnyAction.self, table: "listings")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await listingsChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleListingsChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Listings realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime listings changes - simple refresh strategy
    private func handleListingsChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Listings change detected, refreshing...")

        // Simple approach: re-fetch everything
        await fetchAllListings()
    }

    /// Setup realtime subscription for all activities (for category mapping)
    private func setupActivitiesRealtime() async {
        activitiesRealtimeTask?.cancel()

        // Reuse the channel property (prevents "postgresChange after joining" error)
        activitiesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing
                let stream = activitiesChannel.postgresChange(AnyAction.self, table: "activities")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await activitiesChannel.subscribeWithError()

                // Listen for changes
                for await change in stream {
                    await self.handleActivitiesChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Activities realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime activity changes - simple refresh strategy
    private func handleActivitiesChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Activity change detected, refreshing...")

        // Simple approach: re-fetch everything to rebuild category mapping
        await fetchAllListings()
    }
}
