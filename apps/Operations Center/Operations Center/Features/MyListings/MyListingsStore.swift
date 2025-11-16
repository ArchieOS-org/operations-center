//
//  MyListingsStore.swift
//  Operations Center
//
//  My Listings screen store - shows listings where user has claimed activities
//  Per TASK_MANAGEMENT_SPEC.md lines 197-213
//

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

    /// Filter by team: marketing, admin, or all
    var teamFilter: OperationsCenterKit.TeamFilter = .all

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repositories for data access
    private let listingRepository: ListingRepositoryClient
    private let taskRepository: TaskRepositoryClient

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
            // Fetch all listing tasks for current user (TODO: Get actual user ID from auth)
            let currentUserId = "current-user"

            // Get all listing tasks claimed by this user
            let userListingTasks = try await taskRepository.fetchListingTasks()
                .filter { $0.task.assignedStaffId == currentUserId }

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
            let currentUserId = "current-user" // TODO: Get from auth
            try await listingRepository.deleteListing(listing.id, currentUserId)

            await refresh()
        } catch {
            Logger.database.error("Failed to delete listing: \(error.localizedDescription)")
            errorMessage = "Failed to delete listing: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    /// Filtered listings based on team filter
    /// Per spec: Marketing/Admin/All toggle (lines 209)
    var filteredListings: [Listing] {
        switch teamFilter {
        case .all:
            return listings
        case .marketing:
            // Marketing team sees all listings (buyer and seller side)
            return listings
        case .admin:
            // Admin team sees all listings (buyer and seller side)
            return listings
        }
    }
}
