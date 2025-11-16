//
//  ListingRepositoryClient.swift
//  Operations Center
//
//  Listing repository client for production and preview contexts
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

// MARK: - Listing Repository Client

/// Listing repository client for production and preview contexts
public struct ListingRepositoryClient {
    /// Fetch all listings
    public var fetchListings: @Sendable () async throws -> [Listing]

    /// Fetch a single listing by ID
    public var fetchListing: @Sendable (_ listingId: String) async throws -> Listing?

    /// Fetch listings for a specific realtor
    public var fetchListingsByRealtor: @Sendable (_ realtorId: String) async throws -> [Listing]

    /// Delete a listing (soft delete)
    public var deleteListing: @Sendable (_ listingId: String, _ deletedBy: String) async throws -> Void
}

// MARK: - Live Implementation

extension ListingRepositoryClient {
    /// Production implementation using global Supabase client
    public static let live = Self(
        fetchListings: {
            Logger.database.info("Fetching all listings")
            let listings: [Listing] = try await supabase
                .from("listings")
                .select()
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .execute()
                .value

            Logger.database.info("Fetched \(listings.count) listings")
            return listings
        },
        fetchListing: { listingId in
            Logger.database.info("Fetching listing: \(listingId)")
            let listings: [Listing] = try await supabase
                .from("listings")
                .select()
                .eq("listing_id", value: listingId)
                .is("deleted_at", value: nil)
                .execute()
                .value

            return listings.first
        },
        fetchListingsByRealtor: { realtorId in
            Logger.database.info("Fetching listings for realtor: \(realtorId)")
            let listings: [Listing] = try await supabase
                .from("listings")
                .select()
                .eq("realtor_id", value: realtorId)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .execute()
                .value

            Logger.database.info("Fetched \(listings.count) listings for realtor")
            return listings
        },
        deleteListing: { listingId, deletedBy in
            Logger.database.info("Deleting listing: \(listingId)")
            let now = Date()

            try await supabase
                .from("listings")
                .update([
                    "deleted_at": now.ISO8601Format(),
                    "deleted_by": deletedBy
                ])
                .eq("listing_id", value: listingId)
                .execute()

            Logger.database.info("Successfully deleted listing: \(listingId)")
        }
    )
}

// MARK: - Preview Implementation

extension ListingRepositoryClient {
    /// Preview implementation with mock data for Xcode previews
    public static let preview = Self(
        fetchListings: {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            return [Listing.mock1, Listing.mock2, Listing.mock3]
        },
        fetchListing: { _ in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds
            return Listing.mock1
        },
        fetchListingsByRealtor: { _ in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            return [Listing.mock1, Listing.mock2]
        },
        deleteListing: { _, _ in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds
        }
    )
}
