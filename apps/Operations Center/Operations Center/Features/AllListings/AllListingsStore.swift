//
//  AllListingsStore.swift
//  Operations Center
//
//  All Listings screen store - shows all listings system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 238-253
//

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

    /// Currently expanded listing ID (only one can be expanded at a time)
    var expandedListingId: String?

    /// Filter by team: marketing, admin, or all
    var teamFilter: OperationsCenterKit.TeamFilter = .all

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repository for data access
    private let repository: ListingRepositoryClient

    // MARK: - Initialization

    init(repository: ListingRepositoryClient) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Fetch all listings
    func fetchAllListings() async {
        isLoading = true
        errorMessage = nil

        do {
            listings = try await repository.fetchListings()
            Logger.database.info("Fetched \(self.listings.count) listings")
        } catch {
            Logger.database.error("Failed to fetch all listings: \(error.localizedDescription)")
            errorMessage = "Failed to load listings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await fetchAllListings()
    }

    /// Toggle expansion for a listing
    func toggleExpansion(for listingId: String) {
        expandedListingId = expandedListingId == listingId ? nil : listingId
    }

    /// Delete a listing
    func deleteListing(_ listing: Listing) async {
        do {
            let currentUserId = "current-user" // TODO: Get from auth
            try await repository.deleteListing(listing.id, currentUserId)

            await refresh()
        } catch {
            Logger.database.error("Failed to delete listing: \(error.localizedDescription)")
            errorMessage = "Failed to delete listing: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    /// Filtered listings based on team filter
    /// Per spec: Marketing sees listings with is_buyer_side=false OR true
    /// Admin sees listings with is_buyer_side=true OR false
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
