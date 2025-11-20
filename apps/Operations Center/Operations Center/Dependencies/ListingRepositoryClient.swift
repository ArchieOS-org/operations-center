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
    /// Production implementation with local-first architecture
    /// Reads from local database first, then refreshes from Supabase in background
    public static func live(localDatabase: LocalDatabase) -> Self {
        return Self(
        fetchListings: {
            Logger.database.info("🔍 ListingRepository.fetchListings() - Reading from local database...")

            // Read from local database first for instant UI
            let cachedListings = try await MainActor.run { try localDatabase.fetchListings() }
            Logger.database.info("📱 Local database returned \(cachedListings.count) listings")

            // Background refresh from Supabase
            Task.detached {
                do {
                    Logger.database.info("☁️ Refreshing listings from Supabase...")
                    let listings: [Listing] = try await supabase
                        .from("listings")
                        .select()
                        .is("deleted_at", value: nil)
                        .order("created_at", ascending: false)
                        .execute()
                        .value

                    Logger.database.info("✅ Supabase returned \(listings.count) listings")

                    // Persist to local database
                    try await MainActor.run { try localDatabase.upsertListings(listings) }
                    Logger.database.info("💾 Saved listings to local database")
                } catch {
                    Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                }
            }

            return cachedListings
        },
        fetchListing: { listingId in
            Logger.database.info("🔍 ListingRepository.fetchListing(\(listingId)) - Reading from local database...")

            // Read from local database first
            let cachedListing = try await MainActor.run { try localDatabase.fetchListing(id: listingId) }
            Logger.database.info("📱 Local database returned: \(cachedListing != nil ? "found" : "not found")")

            // Background refresh from Supabase
            Task.detached {
                do {
                    Logger.database.info("☁️ Refreshing listing \(listingId) from Supabase...")
                    let listings: [Listing] = try await supabase
                        .from("listings")
                        .select()
                        .eq("listing_id", value: listingId)
                        .is("deleted_at", value: nil)
                        .execute()
                        .value

                    if let fresh = listings.first {
                        Logger.database.info("✅ Supabase returned listing \(listingId)")
                        try await MainActor.run { try localDatabase.upsertListings([fresh]) }
                        Logger.database.info("💾 Saved listing to local database")
                    }
                } catch {
                    Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                }
            }

            return cachedListing
        },
        fetchListingsByRealtor: { realtorId in
            Logger.database.info("🔍 ListingRepository.fetchListingsByRealtor(\(realtorId)) - Reading from local database...")

            // Read from local database first - filter by realtor_id
            let allCached = try await MainActor.run { try localDatabase.fetchListings() }
            let cachedForRealtor = allCached.filter { $0.realtorId == realtorId }
            Logger.database.info("📱 Local database returned \(cachedForRealtor.count) listings for realtor")

            // Background refresh from Supabase
            Task.detached {
                do {
                    Logger.database.info("☁️ Refreshing realtor \(realtorId) listings from Supabase...")
                    let listings: [Listing] = try await supabase
                        .from("listings")
                        .select()
                        .eq("realtor_id", value: realtorId)
                        .is("deleted_at", value: nil)
                        .order("created_at", ascending: false)
                        .execute()
                        .value

                    Logger.database.info("✅ Supabase returned \(listings.count) listings for realtor")
                    try await MainActor.run { try localDatabase.upsertListings(listings) }
                    Logger.database.info("💾 Saved listings to local database")
                } catch {
                    Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                }
            }

            return cachedForRealtor
        },
        fetchCompletedListings: {
            Logger.database.info("🔍 ListingRepository.fetchCompletedListings() - Reading from local database...")

            // Read from local database first - filter for completed
            let allCached = try await MainActor.run { try localDatabase.fetchListings() }
            let completedCached = allCached.filter { $0.completedAt != nil }
            Logger.database.info("📱 Local database returned \(completedCached.count) completed listings")

            // Background refresh from Supabase
            Task.detached {
                do {
                    Logger.database.info("☁️ Refreshing completed listings from Supabase...")
                    let listings: [Listing] = try await supabase
                        .from("listings")
                        .select()
                        .filter("completed_at", operator: "not.is.null", value: "")
                        .is("deleted_at", value: nil)
                        .order("completed_at", ascending: false)
                        .execute()
                        .value

                    Logger.database.info("✅ Supabase returned \(listings.count) completed listings")
                    try await MainActor.run { try localDatabase.upsertListings(listings) }
                    Logger.database.info("💾 Saved listings to local database")
                } catch {
                    Logger.database.error("❌ Background refresh failed: \(error.localizedDescription)")
                }
            }

            return completedCached
        },
        deleteListing: { listingId, deletedBy in
            Logger.database.info("🗑️ ListingRepository.deleteListing(\(listingId))")
            let now = Date()

            // Update Supabase first
            try await supabase
                .from("listings")
                .update([
                    "deleted_at": now.ISO8601Format(),
                    "deleted_by": deletedBy
                ])
                .eq("listing_id", value: listingId)
                .execute()

            Logger.database.info("✅ Supabase marked listing as deleted")

            // Update local database
            let cachedListing = try await MainActor.run { try localDatabase.fetchListing(id: listingId) }
            if let cachedListing {
                // Create updated listing with deletedAt timestamp
                let updatedListing = Listing(
                    id: cachedListing.id,
                    addressString: cachedListing.addressString,
                    status: cachedListing.status,
                    assignee: cachedListing.assignee,
                    realtorId: cachedListing.realtorId,
                    dueDate: cachedListing.dueDate,
                    progress: cachedListing.progress,
                    type: cachedListing.type,
                    createdAt: cachedListing.createdAt,
                    updatedAt: cachedListing.updatedAt,
                    completedAt: cachedListing.completedAt,
                    deletedAt: now
                )
                try await MainActor.run { try localDatabase.upsertListings([updatedListing]) }
                Logger.database.info("💾 Updated local database with deletion")
            }
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
