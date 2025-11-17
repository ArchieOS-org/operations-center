//
//  AllListingsStore.swift
//  Operations Center
//
//  All Listings store - manages all listings system-wide
//

import Foundation
import OperationsCenterKit
import OSLog
import Dependencies

@Observable
@MainActor
final class AllListingsStore {
    // MARK: - Properties

    /// All listings
    private(set) var listings: [Listing] = [] {
        didSet {
            Logger.database.info("📦 AllListingsStore.listings updated: \(self.listings.count) items")
        }
    }

    /// Category filter selection (nil = "All")
    var selectedCategory: TaskCategory? {
        didSet {
            Logger.database.info("🔄 Category filter changed to: \(String(describing: self.selectedCategory))")
        }
    }

    /// Mapping of listing ID to categories of all tasks for that listing
    private var listingCategories: [String: Set<TaskCategory?>] = [:] {
        didSet {
            Logger.database.info("🗺️ Category mapping updated: \(self.listingCategories.count) listings mapped")
        }
    }

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repository for data access
    private let listingRepository: ListingRepositoryClient
    private let taskRepository: TaskRepositoryClient

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    /// Filtered listings based on selected category
    var filteredListings: [Listing] {
        let result: [Listing]
        
        if self.selectedCategory == nil {
            result = self.listings
            Logger.database.info("🔍 Filter: All (\(result.count) listings)")
        } else {
            result = self.listings.filter { listing in
                self.listingCategories[listing.id]?.contains(selectedCategory) ?? false
            }
            Logger.database.info("🔍 Filter: \(String(describing: selectedCategory)) (\(result.count) listings)")
        }
        
        return result
    }

    // MARK: - Initialization

    init(listingRepository: ListingRepositoryClient, taskRepository: TaskRepositoryClient) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
        Logger.database.info("🏗️ AllListingsStore initialized")
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
            Logger.database.error("   Error type: \(type(of: error))")
            Logger.database.error("   Error details: \(String(describing: error))")
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
        }

        isLoading = false
        Logger.database.info("🏠 AllListingsStore.fetchAllListings() completed")
    }

    /// Refresh listings
    func refresh() async {
        await fetchAllListings()
    }
}
