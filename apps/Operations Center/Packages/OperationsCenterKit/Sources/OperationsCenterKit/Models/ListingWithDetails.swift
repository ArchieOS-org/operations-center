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
    public var notes: [ListingNote]  // Mutable for optimistic updates

    /// Indicates if there was an error loading notes for this listing
    public let hasNotesError: Bool

    /// Indicates if the realtor could not be loaded for this listing
    public let hasMissingRealtor: Bool

    public var id: String { listing.id }

    public init(
        listing: Listing,
        realtor: Realtor?,
        activities: [Activity],
        notes: [ListingNote],
        hasNotesError: Bool = false,
        hasMissingRealtor: Bool = false
    ) {
        self.listing = listing
        self.realtor = realtor
        self.activities = activities
        self.notes = notes
        self.hasNotesError = hasNotesError
        self.hasMissingRealtor = hasMissingRealtor
    }
}
