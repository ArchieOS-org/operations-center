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

    // MARK: - Initialization

    init(listingRepository: ListingRepositoryClient, taskRepository: TaskRepositoryClient) {
        self.listingRepository = listingRepository
        self.taskRepository = taskRepository
    }

    // MARK: - Actions

    /// Fetch all listings where user has claimed at least one activity
    func fetchMyListings() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get activitys claimed by this realtor directly from repository
            let userListingTasks = try await taskRepository.fetchActivitiesByRealtor(authClient.currentUserId())

            // Extract unique listing IDs
            let listingIds = Set(userListingTasks.map { $0.task.listingId })

            // Fetch all listings
            let allListings = try await listingRepository.fetchListings()

            // Filter to only listings where user has claimed activities
            listings = allListings.filter { listing in
                listingIds.contains(listing.id)
            }

            Logger.database.info("Fetched \(self.listings.count) listings with user activities")
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
            try await listingRepository.deleteListing(listing.id, authClient.currentUserId())

            await refresh()
        } catch {
            Logger.database.error("Failed to delete listing: \(error.localizedDescription)")
            errorMessage = "Failed to delete listing: \(error.localizedDescription)"
        }
    }
}
