//
//  ListingTaskCard.swift
//  OperationsCenterKit
//
//  Blue accent, with border, subtasks first
//  First-class citizen for property-linked tasks
//

import SwiftUI

/// Card for displaying listing tasks (property-linked, has a home)
public struct ListingTaskCard: View {
    // MARK: - Properties

    let task: ListingTask
    let subtasks: [Subtask]
    let isExpanded: Bool
    let onTap: () -> Void
    let onSubtaskToggle: (Subtask) -> Void
    let onClaim: () -> Void
    let onDelete: () -> Void

    // MARK: - Initialization

    public init(
        task: ListingTask,
        subtasks: [Subtask],
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onSubtaskToggle: @escaping (Subtask) -> Void,
        onClaim: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.subtasks = subtasks
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onSubtaskToggle = onSubtaskToggle
        self.onClaim = onClaim
        self.onDelete = onDelete
    }

    // MARK: - Body

    public var body: some View {
        CardBase(
            accentColor: Colors.listingAccent,
            backgroundColor: Colors.listingCardBackground,
            hasBorder: true,
            isExpanded: isExpanded,
            onTap: onTap
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                CardHeader(
                    title: task.name,
                    subtitle: propertyAddress,
                    chips: buildChips()
                )

                // Subtasks (when expanded)
                if isExpanded {
                    SubtasksSection(subtasks: subtasks, onToggle: onSubtaskToggle)

                    // Toolbar
                    ListingTaskToolbar(
                        onClaim: onClaim,
                        onDelete: onDelete
                    )
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var propertyAddress: String? {
        // In production, this would fetch the actual property address from listingId
        // For now, return a placeholder that makes sense in context
        return "Property \(task.listingId)"
    }

    // MARK: - Helper Methods

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Assigned agent chip
        if let staffId = task.assignedStaffId {
            chips.append(.agent(name: staffId, style: .listing))
        }

        // Due date chip
        if let dueDate = task.dueDate {
            chips.append(.dueDate(dueDate))
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

    private func categoryColor(for category: ListingTask.TaskCategory) -> Color {
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
    let task = ListingTask(
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

    ListingTaskCard(
        task: task,
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
    let task = ListingTask(
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

    ListingTaskCard(
        task: task,
        subtasks: subtasks,
        isExpanded: true,
        onTap: {},
        onSubtaskToggle: { subtask in
            print("Toggled: \(subtask.name)")
        },
        onClaim: { print("Claim") },
        onDelete: { print("Delete") }
    )
    .padding()
}
