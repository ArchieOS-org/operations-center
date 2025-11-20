//
//  MyListingsStore.swift
//  Operations Center
//
//  My Listings screen store - shows listings where user has claimed activities
//  Per TASK_MANAGEMENT_SPEC.md lines 197-213
//

import Dependencies
import Foundation
import OperationsCenterKit
import OSLog
import Supabase
import SwiftUI

/// Store for My Listings screen - listings where current user has claimed at least one activity
/// Per spec: "Listings where user has claimed at least one Activity"
@Observable
@MainActor
final class MyListingsStore {
    // MARK: - Properties

    /// All listings where user has claimed activities
    private(set) var listings: [Listing] = [] {
        didSet {
            updateFilteredListings()
        }
    }

    /// Category filter selection (nil = "All")
    var selectedCategory: TaskCategory? {
        didSet {
            updateFilteredListings()
        }
    }

    /// Mapping of listing ID to categories of tasks user has claimed
    private var listingCategories: [String: Set<TaskCategory?>] = [:] {
        didSet {
            updateFilteredListings()
        }
    }

    /// Cached filtered listings - updated when listings, category, or mapping changes
    /// Performance: Filter runs once per change, not 60x/second
    private(set) var filteredListings: [Listing] = []

    /// Currently expanded listing ID (only one can be expanded at a time)
    var expandedListingId: String?

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repositories for data access
    private let listingRepository: ListingRepositoryClient
    private let taskRepository: TaskRepositoryClient

    /// Coalescer for request deduplication
    private let listingCoalescer: ListingFetchCoalescer

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    /// Supabase client for realtime subscriptions
    @ObservationIgnored
    private let supabase: SupabaseClient

    /// Realtime channels (created once, prevents "postgresChange after joining" error)
    @ObservationIgnored
    private lazy var activitiesChannel = supabase.realtimeV2.channel("my_listings_activities")

    @ObservationIgnored
    private lazy var listingsChannel = supabase.realtimeV2.channel("my_listings_listings")

    @ObservationIgnored
    private lazy var acknowledgementsChannel = supabase.realtimeV2.channel("my_listings_acknowledgments")

    /// Realtime subscription tasks
    @ObservationIgnored
    private var activitiesRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var listingsRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var acknowledgementsRealtimeTask: Task<Void, Never>?

    // MARK: - Private Methods

    /// Update cached filtered listings when data or filter changes
    /// Performance optimization: Filter runs once per change, not on every SwiftUI redraw
    private func updateFilteredListings() {
        guard let selectedCategory else {
            filteredListings = listings
            return
        }

        filteredListings = listings.filter { listing in
            listingCategories[listing.id]?.contains(selectedCategory) ?? false
        }
    }

    // MARK: - Initialization

    init(
        listingRepository: ListingRepositoryClient,
        taskRepository: TaskRepositoryClient,
        supabase: SupabaseClient,
        listingCoalescer: ListingFetchCoalescer
    ) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
        self.supabase = supabase
        self.listingCoalescer = listingCoalescer
    }

    deinit {
        Task.detached { [weak self] in
            guard let self else { return }
            await activitiesChannel.unsubscribe()
            await listingsChannel.unsubscribe()
            await acknowledgementsChannel.unsubscribe()
        }
        activitiesRealtimeTask?.cancel()
        listingsRealtimeTask?.cancel()
        acknowledgementsRealtimeTask?.cancel()
    }

    // MARK: - Preview Support

    /// Preview factory for SwiftUI previews
    @MainActor
    static func makePreview(supabase: SupabaseClient) -> MyListingsStore {
        MyListingsStore(
            listingRepository: .preview,
            taskRepository: .preview,
            supabase: supabase,
            listingCoalescer: ListingFetchCoalescer()
        )
    }

    // MARK: - Actions

    /// Fetch all listings where user has claimed at least one activity AND has acknowledged
    func fetchMyListings() async {
        Logger.database.info("📱 MyListingsStore.fetchMyListings() starting...")
        isLoading = true
        errorMessage = nil

        do {
            // First: Get user ID (required for subsequent calls)
            let currentUserId = try await authClient.currentUserId()
            Logger.database.info("👤 Current user ID: \(currentUserId)")

            // Then: Fetch activities and listings in PARALLEL
            async let userListingTasks = taskRepository.fetchActivitiesByStaff(currentUserId)
            async let allListings = listingCoalescer.fetch(using: listingRepository)

            let activities = try await userListingTasks
            let listings = try await allListings

            Logger.database.info("📋 User has \(activities.count) claimed activities")
            Logger.database.info("📚 Total listings in database: \(listings.count)")

            // Extract unique listing IDs and build category mapping
            var listingIds = Set<String>()
            var categoryMapping: [String: Set<TaskCategory?>] = [:]

            for activityWithDetails in activities {
                let listingId = activityWithDetails.task.listingId
                listingIds.insert(listingId)

                // Add this task's category to the listing's category set
                if categoryMapping[listingId] == nil {
                    categoryMapping[listingId] = Set()
                }
                categoryMapping[listingId]?.insert(activityWithDetails.task.taskCategory)
            }

            Logger.database.info("🏠 User has activities for \(listingIds.count) unique listings: \(listingIds)")

            // Filter to only listings where:
            // 1. User has claimed activities AND
            // 2. User has acknowledged the listing
            // Batch query - single network call instead of N sequential calls
            let acknowledgedListingIds = try await listingRepository.fetchAcknowledgedListingIds(
                Array(listingIds),
                currentUserId
            )

            Logger.database.info("✅ User has acknowledged \(acknowledgedListingIds.count) listings")

            self.listings = listings.filter { listing in
                acknowledgedListingIds.contains(listing.id)
            }

            // Store category mapping (only for acknowledged listings)
            listingCategories = categoryMapping.filter { acknowledgedListingIds.contains($0.key) }

            Logger.database.info("Fetched \(self.listings.count) acknowledged listings with user activities")

            // Start realtime subscriptions AFTER initial load
            await setupRealtimeSubscriptions()
        } catch {
            Logger.database.error("Failed to fetch my listings: \(error.localizedDescription)")
            errorMessage = "Failed to load your listings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await fetchMyListings()
    }

    /// Toggle expansion for a listing
    func toggleExpansion(for listingId: String) {
        expandedListingId = expandedListingId == listingId ? nil : listingId
    }

    /// Delete a listing
    func deleteListing(_ listing: Listing) async {
        do {
            let userId = try await authClient.currentUserId()
            try await listingRepository.deleteListing(listing.id, userId)

            await refresh()
        } catch {
            Logger.database.error("Failed to delete listing: \(error.localizedDescription)")
            errorMessage = "Failed to delete listing: \(error.localizedDescription)"
        }
    }

    // MARK: - Realtime Subscriptions

    /// Setup all realtime subscriptions
    private func setupRealtimeSubscriptions() async {
        await setupActivitiesRealtime()
        await setupListingsRealtime()
        await setupAcknowledgementsRealtime()
    }

    /// Setup realtime subscription for activities
    private func setupActivitiesRealtime() async {
        activitiesRealtimeTask?.cancel()

        activitiesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = activitiesChannel.postgresChange(AnyAction.self, table: "activities")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await activitiesChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleActivitiesChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("My listings activities realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime activities changes - simple refresh strategy
    private func handleActivitiesChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Activities change detected, refreshing...")

        // Simple approach: re-fetch everything to rebuild category mapping
        await fetchMyListings()
    }

    /// Setup realtime subscription for listings
    private func setupListingsRealtime() async {
        listingsRealtimeTask?.cancel()

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
                Logger.database.error("My listings listings realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime listings changes - simple refresh strategy
    private func handleListingsChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Listings change detected, refreshing...")

        // Simple approach: re-fetch everything
        await fetchMyListings()
    }

    /// Setup realtime subscription for listing acknowledgments
    private func setupAcknowledgementsRealtime() async {
        acknowledgementsRealtimeTask?.cancel()

        acknowledgementsRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = acknowledgementsChannel.postgresChange(AnyAction.self, table: "listing_acknowledgments")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await acknowledgementsChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleAcknowledgementsChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("My listings acknowledgments realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime acknowledgments changes - simple refresh strategy
    private func handleAcknowledgementsChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Acknowledgments change detected, refreshing...")

        // Simple approach: re-fetch everything (acknowledgment state affects visibility)
        await fetchMyListings()
    }
}
