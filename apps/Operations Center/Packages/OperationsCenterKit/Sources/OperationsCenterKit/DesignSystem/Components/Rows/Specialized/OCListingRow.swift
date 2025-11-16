//
//  OCListingRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Canonical representation of a listing summary row
/// Used across AllListings, MyListings, Logbook, Inbox listing section
public struct OCListingRow<ExpandedContent: View>: View {
    private let listing: Listing
    private let realtor: Realtor?
    private let isExpanded: Bool
    private let onTap: (() -> Void)?
    private let expandedContent: ExpandedContent?

    public init(
        listing: Listing,
        realtor: Realtor? = nil,
        isExpanded: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.listing = listing
        self.realtor = realtor
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.expandedContent = expandedContent()
    }

    public var body: some View {
        OCRow(
            expansionStyle: expandedContent != nil ? .inline : .none,
            isExpanded: isExpanded,
            onTap: onTap
        ) {
            // Main content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Primary: Address
                Text(listing.addressString)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                // Secondary: Realtor name
                if let realtor {
                    Text(realtor.name)
                        .font(Typography.cardSubtitle)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                // Chips row
                HStack(spacing: Spacing.sm) {
                    // Listing type chip
                    if let typeString = listing.type,
                       let listingType = ListingType(rawValue: typeString) {
                        DSChip(
                            text: listingType.rawValue.lowercased().capitalized,
                            color: listingType.color
                        )
                    }

                    // Due date chip (if present)
                    if let dueDate = listing.dueDate {
                        DSChip(date: dueDate)
                    }

                    Spacer(minLength: 0)
                }
            }
        } expandedContent: {
            // Expanded content (NotesSection, activities, etc.)
            if let expandedContent {
                expandedContent
                    .padding(.top, Spacing.sm)
            }
        } accessory: {
            EmptyView()
        }
    }
}

// MARK: - Convenience Initializer

extension OCListingRow where ExpandedContent == EmptyView {
    /// Initialize without expanded content for non-expandable listing rows
    public init(
        listing: Listing,
        realtor: Realtor? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.listing = listing
        self.realtor = realtor
        self.isExpanded = false
        self.onTap = onTap
        self.expandedContent = nil
    }
}