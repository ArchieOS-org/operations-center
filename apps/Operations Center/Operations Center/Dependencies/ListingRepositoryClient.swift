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

    /// Fetch completed listings (for Logbook)
    public var fetchCompletedListings: @Sendable () async throws -> [Listing]

    /// Delete a listing (soft delete)
    public var deleteListing: @Sendable (_ listingId: String, _ deletedBy: String) async throws -> Void

    /// Acknowledge a listing for a specific staff member
    public var acknowledgeListing: @Sendable (
        _ listingId: String,
        _ staffId: String
    ) async throws -> ListingAcknowledgment

    /// Check if a staff member has acknowledged a listing
    public var hasAcknowledged: @Sendable (_ listingId: String, _ staffId: String) async throws -> Bool

    /// Fetch acknowledged listing IDs for a staff member (batch operation)
    /// Returns Set of listing IDs that the staff member has acknowledged
    /// Single query using .in() filter - 10x faster than sequential hasAcknowledged calls
    public var fetchAcknowledgedListingIds: @Sendable (
        _ listingIds: [String],
        _ staffId: String
    ) async throws -> Set<String>

    /// Fetch unacknowledged listings for a staff member
    public var fetchUnacknowledgedListings: @Sendable (_ staffId: String) async throws -> [Listing]
}

// MARK: - Live Implementation

extension ListingRepositoryClient {
    /// Production implementation using global Supabase client
    public static let live = Self(
        fetchListings: {
            Logger.database.info("🔍 ListingRepository.fetchListings() - Starting query...")
            let listings: [Listing] = try await supabase
                .from("listings")
                .select()
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .execute()
                .value

            Logger.database.info("✅ Supabase returned \(listings.count) listings")
            if !listings.isEmpty {
                Logger.database.info("📋 Listing IDs from database: \(listings.map { $0.id })")
            } else {
                Logger.database.warning("⚠️ NO LISTINGS IN DATABASE - listings table is empty or all are deleted")
            }
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
        fetchCompletedListings: {
            Logger.database.info("Fetching completed listings")
            let listings: [Listing] = try await supabase
                .from("listings")
                .select()
                .not("completed_at", operator: .is, value: nil)
                .is("deleted_at", value: nil)
                .order("completed_at", ascending: false)
                .execute()
                .value

            Logger.database.info("Fetched \(listings.count) completed listings")
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
        },
        acknowledgeListing: { listingId, staffId in
            Logger.database.info("Acknowledging listing \(listingId) for staff \(staffId)")

            let ack: ListingAcknowledgment = try await supabase
                .from("listing_acknowledgments")
                .insert([
                    "listing_id": listingId,
                    "staff_id": staffId,
                    "acknowledged_at": Date().ISO8601Format(),
                    "acknowledged_from": "mobile"
                ])
                .select()
                .single()
                .execute()
                .value

            Logger.database.info("Successfully acknowledged listing: \(listingId)")
            return ack
        },
        hasAcknowledged: { listingId, staffId in
            Logger.database.info("Checking acknowledgment for listing \(listingId), staff \(staffId)")

            let acks: [ListingAcknowledgment] = try await supabase
                .from("listing_acknowledgments")
                .select()
                .eq("listing_id", value: listingId)
                .eq("staff_id", value: staffId)
                .execute()
                .value

            return !acks.isEmpty
        },
        fetchAcknowledgedListingIds: { listingIds, staffId in
            guard !listingIds.isEmpty else {
                return []
            }

            Logger.database.debug("Batch checking acknowledgments for \(listingIds.count) listings")

            let acks: [ListingAcknowledgment] = try await supabase
                .from("listing_acknowledgments")
                .select()
                .in("listing_id", values: listingIds)
                .eq("staff_id", value: staffId)
                .execute()
                .value

            let acknowledgedIds = Set(acks.map { $0.listingId })
            Logger.database.debug("Found \(acknowledgedIds.count) acknowledged listings")

            return acknowledgedIds
        },
        fetchUnacknowledgedListings: { staffId in
            Logger.database.info("Fetching unacknowledged listings for staff \(staffId)")

            // Get all active listings
            let allListings: [Listing] = try await supabase
                .from("listings")
                .select()
                .is("deleted_at", value: nil)
                .is("completed_at", value: nil)
                .order("created_at", ascending: false)
                .execute()
                .value

            Logger.database.info("📚 Total active listings in database: \(allListings.count)")

            // Get acknowledged listing IDs for this staff member
            let acknowledged: [ListingAcknowledgment] = try await supabase
                .from("listing_acknowledgments")
                .select()
                .eq("staff_id", value: staffId)
                .execute()
                .value

            Logger.database.info("✅ Staff \(staffId) has acknowledged \(acknowledged.count) listings")

            let acknowledgedIds = Set(acknowledged.map { $0.listingId })

            if !acknowledgedIds.isEmpty {
                Logger.database.info("📋 Acknowledged listing IDs: \(acknowledgedIds)")
            }

            // Filter out acknowledged listings
            let unacknowledged = allListings.filter { !acknowledgedIds.contains($0.id) }

            Logger.database.info("🔔 Found \(unacknowledged.count) unacknowledged listings to show")
            if !unacknowledged.isEmpty {
                Logger.database.info("📍 Unacknowledged listing IDs: \(unacknowledged.map { $0.id })")
            }

            return unacknowledged
        }
    )
}

// MARK: - Preview Implementation

extension ListingRepositoryClient {
    /// Preview implementation with mock data for Xcode previews
    public static let preview = Self(
        fetchListings: {
            return [Listing.mock1, Listing.mock2, Listing.mock3]
        },
        fetchListing: { _ in
            return Listing.mock1
        },
        fetchListingsByRealtor: { _ in
            return [Listing.mock1, Listing.mock2]
        },
        fetchCompletedListings: {
            // Return mock3 which is marked as completed
            return [Listing.mock3]
        },
        deleteListing: { _, _ in
        },
        acknowledgeListing: { listingId, staffId in
            return ListingAcknowledgment(
                listingId: listingId,
                staffId: staffId,
                acknowledgedAt: Date(),
                acknowledgedFrom: .mobile
            )
        },
        hasAcknowledged: { _, _ in
            return false
        },
        fetchAcknowledgedListingIds: { _, _ in
            return []
        },
        fetchUnacknowledgedListings: { _ in
            return [Listing.mock1, Listing.mock2]
        }
    )
}
