//
//  ActivityCard.swift
//  OperationsCenterKit
//
//  Blue accent, with border, subtasks first
//  First-class citizen for property-linked activities
//

import SwiftUI

/// Card for displaying activities (property-linked, has a home)
public struct ActivityCard: View {
    // MARK: - Properties

    let task: Activity
    let listing: Listing
    let subtasks: [Subtask]
    let isExpanded: Bool
    let onTap: () -> Void
    let onSubtaskToggle: (Subtask) -> Void
    let onClaim: () -> Void
    let onDelete: () -> Void

    // MARK: - Initialization

    public init(
        task: Activity,
        listing: Listing,
        subtasks: [Subtask],
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onSubtaskToggle: @escaping (Subtask) -> Void,
        onClaim: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.listing = listing
        self.subtasks = subtasks
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onSubtaskToggle = onSubtaskToggle
        self.onClaim = onClaim
        self.onDelete = onDelete
    }

    // MARK: - Body

    public var body: some View {
        ExpandableCardWrapper(
            tintColor: Colors.listingCardTint,
            isExpanded: isExpanded,
            actions: buildActions(),
            onTap: onTap
        ) {
            // Collapsed content (always shown)
            CardHeader(
                title: listing.addressString,
                subtitle: task.assignedStaffId ?? "Unassigned",
                chips: buildChips(),
                dueDate: task.dueDate,
                isExpanded: isExpanded
            )
        } expandedContent: {
            // Expanded content (only when expanded)
            ActivitiesSection(subtasks: subtasks, onToggle: onSubtaskToggle)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Helper Methods

    private func buildActions() -> [DSContextAction] {
        DSContextAction.standardTaskActions(onClaim: onClaim, onDelete: onDelete)
    }

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
                color: .blue
            ))
        }

        // Category chip
        chips.append(.custom(
            text: task.taskCategory.rawValue,
            color: categoryColor(for: task.taskCategory)
        ))

        // Visibility group chip (if restricted)
        if task.visibilityGroup != .both {
            chips.append(.custom(
                text: task.visibilityGroup.rawValue,
                color: .orange
            ))
        }

        return chips
    }

    private func categoryColor(for category: Activity.TaskCategory) -> Color {
        switch category {
        case .admin: return .blue
        case .marketing: return .purple
        case .photo: return .pink
        case .staging: return .green
        case .inspection: return .red
        case .other: return .gray
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
        agentId: "realtor-1",
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
        subtasks: [],
        isExpanded: false,
        onTap: {},
        onSubtaskToggle: { _ in },
        onClaim: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Expanded with Subtasks") {
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
        agentId: "realtor-1",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 50.0,
        type: "LUXURY",
        notes: "",
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    let subtasks = [
        Subtask(
            id: "1",
            parentTaskId: "1",
            name: "Deep clean all rooms",
            isCompleted: true,
            completedAt: Date(),
            createdAt: Date()
        ),
        Subtask(
            id: "2",
            parentTaskId: "1",
            name: "Touch up paint in living room",
            isCompleted: true,
            completedAt: Date(),
            createdAt: Date()
        ),
        Subtask(
            id: "3",
            parentTaskId: "1",
            name: "Landscape front yard",
            isCompleted: false,
            createdAt: Date()
        ),
        Subtask(
            id: "4",
            parentTaskId: "1",
            name: "Stage master bedroom",
            isCompleted: false,
            createdAt: Date()
        )
    ]

    ActivityCard(
        task: task,
        listing: listing,
        subtasks: subtasks,
        isExpanded: true,
        onTap: {},
        onSubtaskToggle: { _ in },
        onClaim: {},
        onDelete: {}
    )
    .padding()
}
