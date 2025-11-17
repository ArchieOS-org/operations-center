//
//  OCActivityRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Row representation for property tasks currently shown with ActivityCard
public struct OCActivityRow<ExpandedContent: View>: View {
    private let activity: Activity
    private let listing: Listing?
    private let isExpanded: Bool
    private let onTap: (() -> Void)?
    private let expandedContent: ExpandedContent?

    public init(
        activity: Activity,
        listing: Listing? = nil,
        isExpanded: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.activity = activity
        self.listing = listing
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
            HStack(spacing: Spacing.md) {
                // Status dot on the leading edge
                Circle()
                    .fill(activity.status.statusColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Primary: Activity name
                    Text(activity.name)
                        .font(Typography.cardTitle)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    // Secondary: Listing address (if present)
                    if let listing {
                        Text(listing.addressString)
                            .font(Typography.cardSubtitle)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    // Chips row
                    HStack(spacing: Spacing.sm) {
                        // Category chip
                        DSChip(
                            text: activity.taskCategory.displayName,
                            color: Colors.accentListing
                        )

                        // Assignee chip (if present)
                        if let assignedStaffId = activity.assignedStaffId {
                            DSChip(
                                text: assignedStaffId,
                                color: Colors.accentListing
                            )
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        } expandedContent: {
            // Expanded content (ActivitiesSection for subtasks)
            if let expandedContent {
                expandedContent
                    .padding(.top, Spacing.sm)
            }
        } accessory: {
            // Due date chip as trailing accessory when present
            if let dueDate = activity.dueDate {
                DSChip(date: dueDate)
            }
        }
    }
}

// MARK: - Convenience Initializer

extension OCActivityRow where ExpandedContent == EmptyView {
    /// Initialize without expanded content
    public init(
        activity: Activity,
        listing: Listing? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.activity = activity
        self.listing = listing
        self.isExpanded = false
        self.onTap = onTap
        self.expandedContent = nil
    }
}