//
//  ListingCollapsedContent.swift
//  OperationsCenterKit
//
//  Single source of truth for collapsed listing display
//  Used by: ListingBrowseCard (with card chrome), AllListingsView (plain list rows)
//

import SwiftUI

/// Collapsed listing content - shows listing title, realtor name, type chip, and due date
/// This is the shared layout used everywhere a collapsed listing appears
public struct ListingCollapsedContent: View {
    // MARK: - Properties

    let listing: Listing
    let realtor: Realtor?

    // MARK: - Initialization

    public init(listing: Listing, realtor: Realtor? = nil) {
        self.listing = listing
        self.realtor = realtor
    }

    // MARK: - Body

    public var body: some View {
        CardHeader(
            title: listing.title,
            subtitle: realtor?.name,
            chips: buildChips(),
            dueDate: listing.dueDate,
            isExpanded: false
        )
    }

    // MARK: - Helper Methods

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Listing type chip only
        if let listingType = listing.listingType {
            chips.append(.custom(
                text: listingType.rawValue,
                color: listingType.color
            ))
        }

        return chips
    }
}

// MARK: - Preview

#Preview("Active Listing") {
    ListingCollapsedContent(listing: Listing.mock1, realtor: .mock1)
        .padding()
}

#Preview("Pending Listing") {
    ListingCollapsedContent(listing: Listing.mock2, realtor: .mock2)
        .padding()
}

#Preview("Completed Listing") {
    ListingCollapsedContent(listing: Listing.mock3, realtor: .mock1)
        .padding()
}
