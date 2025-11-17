//
//  AllListingsStore.swift
//  Operations Center
//
//  All Listings screen store - shows all listings system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 238-253
//

import Dependencies
import Foundation
import OperationsCenterKit
import OSLog
import SwiftUI

/// Store for All Listings screen - all active listings across the entire system
/// Per spec: "All Listings - Displays all active listings in the system"
@Observable
@MainActor
final class AllListingsStore {
    // MARK: - Properties

    /// All listings
    private(set) var listings: [Listing] = []

    /// Category filter selection (nil = "All")
    var selectedCategory: TaskCategory?

    /// Mapping of listing ID to categories of all tasks for that listing
    private var listingCategories: [String: Set<TaskCategory?>] = [:]

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repository for data access
    private let listingRepository: ListingRepositoryClient
    private let taskRepository: TaskRepositoryClient

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Computed Properties

    /// Filtered listings based on selected category
    var filteredListings: [Listing] {
        guard let selectedCategory else { return listings } // "All" selected

        return listings.filter { listing in
            listingCategories[listing.id]?.contains(selectedCategory) ?? false
        }
    }

    // MARK: - Initialization

    init(listingRepository: ListingRepositoryClient, taskRepository: TaskRepositoryClient) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
    }

    // MARK: - Actions

    /// Fetch all listings
    func fetchAllListings() async {
        Logger.database.info("🏠 AllListingsStore.fetchAllListings() starting...")
        isLoading = true
        errorMessage = nil

        do {
            Logger.database.info("📡 Fetching listings and activities in parallel...")

            // Fetch both listings and activities in parallel
            async let listingsResult = listingRepository.fetchListings()
            async let activitiesResult = taskRepository.fetchActivities()

            let (allListings, allActivities) = try await (listingsResult, activitiesResult)

            Logger.database.info("✅ Received \(allListings.count) listings and \(allActivities.count) activities")

            // Build category mapping from activities
            var categoryMapping: [String: Set<TaskCategory?>] = [:]
            for activityWithDetails in allActivities {
                let listingId = activityWithDetails.task.listingId

                if categoryMapping[listingId] == nil {
                    categoryMapping[listingId] = Set()
                }
                categoryMapping[listingId]?.insert(activityWithDetails.task.taskCategory)
            }

            listings = allListings
            listingCategories = categoryMapping

            Logger.database.info("🏁 AllListingsStore now has \(self.listings.count) listings")
            if !listings.isEmpty {
                Logger.database.info("📋 Listing IDs: \(self.listings.map { $0.id })")
            }
        } catch {
            Logger.database.error("❌ Failed to fetch all listings: \(error.localizedDescription)")
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
        }

        isLoading = false
        Logger.database.info("🏠 AllListingsStore.fetchAllListings() completed")
    }

    /// Refresh data
    func refresh() async {
        await fetchAllListings()
    }

    /// Delete a listing
    func deleteListing(_ listing: Listing) async {
        do {
            try await listingRepository.deleteListing(listing.id, await authClient.currentUserId())

            await refresh()
        } catch {
            Logger.database.error("Failed to delete listing: \(error.localizedDescription)")
            errorMessage = "Failed to delete listing: \(error.localizedDescription)"
        }
    }
}
