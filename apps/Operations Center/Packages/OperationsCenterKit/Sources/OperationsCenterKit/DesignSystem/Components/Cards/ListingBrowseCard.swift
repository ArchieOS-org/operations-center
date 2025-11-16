//
//  ListingBrowseCard.swift
//  OperationsCenterKit
//
//  Collapsed listing with card chrome (background, border, padding)
//  Per TASK_MANAGEMENT_SPEC.md lines 314-316: "Collapsed only - Click → Navigate to Listing Screen"
//  Used in: My Listings, Agent Detail (card views)
//

import SwiftUI

/// Listing card for browse views - wraps ListingCollapsedContent with card chrome
public struct ListingBrowseCard: View {
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
        ListingCollapsedContent(listing: listing, realtor: realtor)
            .padding(Spacing.md)
            .background(Colors.listingCardTint.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .stroke(Colors.listingCardTint, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Active Listing") {
    ListingBrowseCard(listing: Listing.mock1, realtor: .mock1)
        .padding()
}

#Preview("Pending Listing") {
    ListingBrowseCard(listing: Listing.mock2, realtor: .mock2)
        .padding()
}

#Preview("Completed Listing") {
    ListingBrowseCard(listing: Listing.mock3, realtor: .mock1)
        .padding()
}
