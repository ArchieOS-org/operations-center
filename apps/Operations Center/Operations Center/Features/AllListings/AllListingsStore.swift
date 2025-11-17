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
            updateFilteredListings()
        }
    }

    /// Category filter selection (nil = "All")
    var selectedCategory: TaskCategory? {
        didSet {
            updateFilteredListings()
        }
    }

    /// Mapping of listing ID to categories of all tasks for that listing
    private var listingCategories: [String: Set<TaskCategory?>] = [:] {
        didSet {
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

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    init(listingRepository: ListingRepositoryClient, taskRepository: TaskRepositoryClient) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
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
            // Fetch both listings and activities in parallel
            async let listingsResult = listingRepository.fetchListings()
            async let activitiesResult = taskRepository.fetchActivities()

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

            listings = allListings
            listingCategories = categoryMapping
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
}
