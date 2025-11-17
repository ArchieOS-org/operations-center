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
import SwiftUI

/// Store for My Listings screen - listings where current user has claimed at least one activity
/// Per spec: "Listings where user has claimed at least one Activity"
@Observable
@MainActor
final class MyListingsStore {
    // MARK: - Properties

    /// All listings where user has claimed activities
    private(set) var listings: [Listing] = []

    /// Category filter selection (nil = "All")
    var selectedCategory: TaskCategory?

    /// Mapping of listing ID to categories of tasks user has claimed
    private var listingCategories: [String: Set<TaskCategory?>] = [:]

    /// Currently expanded listing ID (only one can be expanded at a time)
    var expandedListingId: String?

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repositories for data access
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

    /// Fetches listings that the current user both has claimed activities for and has acknowledged, then updates the store state accordingly.
/// 
/// On success, updates `listings` with acknowledged listings that contain the user's claimed activities and populates `listingCategories` with the per-listing set of claimed task categories. On failure, sets `errorMessage`. Always updates `isLoading` to reflect the fetch lifecycle.
    func fetchMyListings() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentUserId = authClient.currentUserId()

            // Get activities claimed by this staff member directly from repository
            let userListingTasks = try await taskRepository.fetchActivitiesByStaff(currentUserId)

            // Extract unique listing IDs and build category mapping
            var listingIds = Set<String>()
            var categoryMapping: [String: Set<TaskCategory?>] = [:]

            for activityWithDetails in userListingTasks {
                let listingId = activityWithDetails.task.listingId
                listingIds.insert(listingId)

                // Add this task's category to the listing's category set
                if categoryMapping[listingId] == nil {
                    categoryMapping[listingId] = Set()
                }
                categoryMapping[listingId]?.insert(activityWithDetails.task.taskCategory)
            }

            // Fetch all listings
            let allListings = try await listingRepository.fetchListings()

            // Filter to only listings where:
            // 1. User has claimed activities AND
            // 2. User has acknowledged the listing
            var acknowledgedListingIds: Set<String> = []
            for listingId in listingIds where try await listingRepository.hasAcknowledged(listingId, currentUserId) {
                acknowledgedListingIds.insert(listingId)
            }

            listings = allListings.filter { listing in
                acknowledgedListingIds.contains(listing.id)
            }

            // Store category mapping (only for acknowledged listings)
            listingCategories = categoryMapping.filter { acknowledgedListingIds.contains($0.key) }

            Logger.database.info("Fetched \(self.listings.count) acknowledged listings with user activities")
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

    /// Deletes the provided listing on behalf of the current user and refreshes the store on success.
    /// - Parameter listing: The listing to delete.
    /// - Note: On failure the method logs the error and stores an error message in `errorMessage`.
    func deleteListing(_ listing: Listing) async {
        do {
            try await listingRepository.deleteListing(listing.id, authClient.currentUserId())

            await refresh()
        } catch {
            Logger.database.error("Failed to delete listing: \(error.localizedDescription)")
            errorMessage = "Failed to delete listing: \(error.localizedDescription)"
        }
    }
}