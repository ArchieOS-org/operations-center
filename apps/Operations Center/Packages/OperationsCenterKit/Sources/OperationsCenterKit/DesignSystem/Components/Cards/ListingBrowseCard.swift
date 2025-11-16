//
//  ListingBrowseCard.swift
//  OperationsCenterKit
//
//  Simple collapsed-only card for browsing listings
//  Per TASK_MANAGEMENT_SPEC.md lines 314-316: "Collapsed only - Click → Navigate to Listing Screen"
//  Used in: All Listings, My Listings, Agent Detail
//

import SwiftUI

/// Simple listing card for browse views - always collapsed, taps handled by parent
public struct ListingBrowseCard: View {
    // MARK: - Properties

    let listing: Listing

    // MARK: - Initialization

    public init(listing: Listing) {
        self.listing = listing
    }

    // MARK: - Body

    public var body: some View {
        CardHeader(
            title: "",
            subtitle: listing.title,
            chips: buildChips(),
            dueDate: listing.dueDate,
            isExpanded: false
        )
        .padding(Spacing.md)
        .background(Colors.listingCardTint.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Colors.listingCardTint, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Helper Methods

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Listing type chip only
        if let type = listing.type {
            chips.append(.custom(
                text: type,
                color: typeColor(for: type)
            ))
        }

        return chips
    }

    private func typeColor(for type: String) -> Color {
        switch type.uppercased() {
        case "SALE": return .blue
        case "RENTAL": return .purple
        case "COMMERCIAL": return .orange
        case "RESIDENTIAL": return .green
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview("Active Listing") {
    ListingBrowseCard(listing: Listing.mock1)
        .padding()
}

#Preview("Pending Listing") {
    ListingBrowseCard(listing: Listing.mock2)
        .padding()
}

#Preview("Completed Listing") {
    ListingBrowseCard(listing: Listing.mock3)
        .padding()
}
