//
//  ListingWithDetails.swift
//  OperationsCenterKit
//
//  Data structure for listings with all associated activities, notes, and realtor
//

import Foundation

/// Listing bundled with all activities, notes, and realtor details
public struct ListingWithDetails: Sendable, Identifiable {
    public let listing: Listing
    public let realtor: Realtor?
    public let activities: [Activity]
    public let notes: [ListingNote]

    public var id: String { listing.id }

    public init(
        listing: Listing,
        realtor: Realtor?,
        activities: [Activity],
        notes: [ListingNote]
    ) {
        self.listing = listing
        self.realtor = realtor
        self.activities = activities
        self.notes = notes
    }
}
