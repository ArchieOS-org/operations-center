//
//  ListingBrowseCard.swift
//  OperationsCenterKit
//
//  Simple collapsed-only card for browsing listings
//  Per TASK_MANAGEMENT_SPEC.md lines 314-316: "Collapsed only - Click → Navigate to Listing Screen"
//  Used in: All Listings, My Listings, Agent Detail
//

import SwiftUI

/// Simple listing card for browse views - always collapsed, taps navigate to detail
public struct ListingBrowseCard: View {
    // MARK: - Properties

    let listing: Listing
    let onTap: () -> Void

    // MARK: - Initialization

    public init(
        listing: Listing,
        onTap: @escaping () -> Void
    ) {
        self.listing = listing
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        Button(action: onTap) {
            CardHeader(
                title: listing.title,
                subtitle: listing.status,
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
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Agent chip
        if let agentId = listing.agentId {
            chips.append(.agent(name: agentId, style: .listing))
        }

        // Listing type chip
        if let type = listing.type {
            chips.append(.custom(
                text: type,
                color: typeColor(for: type)
            ))
        }

        // Progress chip (if in progress)
        if let progress = listing.progress, progress > 0 {
            // Convert Decimal to Int with safe clamping to 0-100 range
            var roundedProgress = progress
            var result: Decimal = 0
            NSDecimalRound(&result, &roundedProgress, 0, .plain)
            let progressPercent = min(100, max(0, Int(truncating: result as NSDecimalNumber)))
            chips.append(.custom(
                text: "\(progressPercent)%",
                color: progressPercent >= 75 ? .green : .orange
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
    ListingBrowseCard(
        listing: Listing.mock1,
        onTap: { }
    )
    .padding()
}

#Preview("Pending Listing") {
    ListingBrowseCard(
        listing: Listing.mock2,
        onTap: { }
    )
    .padding()
}

#Preview("Completed Listing") {
    ListingBrowseCard(
        listing: Listing.mock3,
        onTap: { }
    )
    .padding()
}
