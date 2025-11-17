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

    /// Fetch all listings where user has claimed at least one activity AND has acknowledged
    func fetchMyListings() async {
        Logger.database.info("📱 MyListingsStore.fetchMyListings() starting...")
        isLoading = true
        errorMessage = nil

        do {
            let currentUserId = await authClient.currentUserId()
            Logger.database.info("👤 Current user ID: \(currentUserId)")

            // Get activities claimed by this staff member directly from repository
            let userListingTasks = try await taskRepository.fetchActivitiesByStaff(currentUserId)
            Logger.database.info("📋 User has \(userListingTasks.count) claimed activities")

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

            Logger.database.info("🏠 User has activities for \(listingIds.count) unique listings: \(listingIds)")

            // Fetch all listings
            let allListings = try await listingRepository.fetchListings()
            Logger.database.info("📚 Total listings in database: \(allListings.count)")

            // Filter to only listings where:
            // 1. User has claimed activities AND
            // 2. User has acknowledged the listing
            var acknowledgedListingIds: Set<String> = []
            for listingId in listingIds {
                let hasAck = try await listingRepository.hasAcknowledged(listingId, currentUserId)
                Logger.database.info("Listing \(listingId): acknowledged=\(hasAck)")
                if hasAck {
                    acknowledgedListingIds.insert(listingId)
                }
            }

            Logger.database.info("✅ User has acknowledged \(acknowledgedListingIds.count) listings: \(acknowledgedListingIds)")

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
