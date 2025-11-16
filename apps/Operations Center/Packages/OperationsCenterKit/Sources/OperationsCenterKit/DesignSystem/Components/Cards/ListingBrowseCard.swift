//
//  ListingBrowseCard.swift
//  OperationsCenterKit
//
//  Collapsed listing with card chrome (background, border, padding)
//  Per TASK_MANAGEMENT_SPEC.md lines 314-316: "Collapsed only - Click → Navigate to Listing Screen"
//  Used in: My Listings, Agent Detail (card views)
//

import SwiftUI

/// Non-interactive listing card for browse views
/// Wraps ListingCollapsedContent with card chrome (background, border, padding)
/// Callers must wrap this in a Button or NavigationLink to handle taps and navigation
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
            .padding(Spacing.lg)
            .background(Colors.surfaceListingTinted)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Colors.accentListing.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
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
