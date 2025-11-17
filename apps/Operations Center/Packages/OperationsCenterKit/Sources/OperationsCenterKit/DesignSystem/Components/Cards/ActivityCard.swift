//
//  ActivityCard.swift
//  OperationsCenterKit
//
//  Blue accent card for property-linked activities
//

import SwiftUI

/// Card for displaying activities (property-linked tasks)
public struct ActivityCard: View {
    // MARK: - Properties

    let task: Activity
    let listing: Listing
    let isExpanded: Bool
    let onTap: () -> Void

    // MARK: - Initialization

    public init(
        task: Activity,
        listing: Listing,
        isExpanded: Bool,
        onTap: @escaping () -> Void
    ) {
        self.task = task
        self.listing = listing
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        ExpandableCardWrapper(
            tintColor: Colors.surfaceListingTinted,
            isExpanded: isExpanded,
            onTap: onTap
        ) {
            // Card content
            CardHeader(
                title: listing.addressString,
                subtitle: task.assignedStaffId ?? "Unassigned",
                chips: buildChips(),
                dueDate: task.dueDate,
                isExpanded: isExpanded
            )
        } expandedContent: {
            // Expanded content (only when expanded)
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Activity name
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(task.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                // Description/Notes
                if let description = task.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }

                // Metadata grid
                MetadataGrid(columnCount: 2) {
                    MetadataItem(
                        label: "Property",
                        value: listing.addressString
                    )

                    MetadataItem(
                        label: "Created",
                        value: task.createdAt.formatted(date: .abbreviated, time: .omitted)
                    )

                    if let claimedAt = task.claimedAt {
                        MetadataItem(
                            label: "Claimed",
                            value: claimedAt.formatted(date: .abbreviated, time: .omitted)
                        )
                    }

                    if let dueDate = task.dueDate {
                        MetadataItem(
                            label: "Due",
                            value: dueDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    }

                    if let completedAt = task.completedAt {
                        MetadataItem(
                            label: "Completed",
                            value: completedAt.formatted(date: .abbreviated, time: .omitted)
                        )
                    }

                    MetadataItem(
                        label: "Status",
                        value: task.status.displayName
                    )

                    MetadataItem(
                        label: "Category",
                        value: task.taskCategory.displayName
                    )
                }
            }
            .padding(Spacing.md)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)),
                removal: .opacity
            ))
        }
    }

    // MARK: - Helper Methods

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Assigned agent chip
        if let staffId = task.assignedStaffId {
            chips.append(.agent(name: staffId, style: .activity))
        }

        // Listing type chip (if present)
        if let listingType = listing.type {
            chips.append(.custom(
                text: listingType,
                color: Colors.accentListing
            ))
        }

        // Category chip (if categorized)
        if let category = task.taskCategory {
            chips.append(.custom(
                text: category.rawValue,
                color: categoryColor(for: category)
            ))
        }

        // Visibility group chip (if restricted)
        if task.visibilityGroup != .both {
            chips.append(.custom(
                text: task.visibilityGroup.rawValue,
                color: Colors.accentAgentTask
            ))
        }

        return chips
    }

    private func categoryColor(for category: TaskCategory) -> Color {
        switch category {
        case .admin: return Colors.categoryAdmin
        case .marketing: return Colors.categoryMarketing
        }
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    let task = Activity(
        id: "1",
        listingId: "listing-001",
        realtorId: "realtor-1",
        name: "Pre-listing prep",
        description: "Prepare property for market launch",
        taskCategory: .admin,
        status: .open,
        priority: 1,
        visibilityGroup: .both,
        assignedStaffId: "Mike Torres",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        claimedAt: nil,
        completedAt: nil,
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        deletedAt: nil,
        deletedBy: nil,
        inputs: nil,
        outputs: nil
    )

    let listing = Listing(
        id: "listing-001",
        addressString: "123 Maple Street",
        status: "new",
        assignee: nil,
        realtorId: "realtor-1",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 0.0,
        type: "RESIDENTIAL",
        notes: "",
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    ActivityCard(
        task: task,
        listing: listing,
        isExpanded: false,
        onTap: {}
    )
    .padding()
}

#Preview("Expanded") {
    let task = Activity(
        id: "1",
        listingId: "listing-001",
        realtorId: "realtor-1",
        name: "123 Maple Street pre-listing prep",
        description: "Prepare property for market launch",
        taskCategory: .admin,
        status: .open,
        priority: 1,
        visibilityGroup: .both,
        assignedStaffId: nil,
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        claimedAt: nil,
        completedAt: nil,
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        deletedAt: nil,
        deletedBy: nil,
        inputs: nil,
        outputs: nil
    )

    let listing = Listing(
        id: "listing-001",
        addressString: "123 Maple Street",
        status: "in_progress",
        assignee: nil,
        realtorId: "realtor-1",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 50.0,
        type: "LUXURY",
        notes: "",
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    ActivityCard(
        task: task,
        listing: listing,
        isExpanded: true,
        onTap: {}
    )
    .padding()
}
