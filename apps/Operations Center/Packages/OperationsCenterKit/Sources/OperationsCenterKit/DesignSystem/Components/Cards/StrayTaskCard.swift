//
//  StrayTaskCard.swift
//  OperationsCenterKit
//
//  Orange accent, no border, Slack messages first
//  First-class citizen for orphaned tasks
//

import SwiftUI

/// Card for displaying stray tasks (orphaned, untethered tasks)
public struct StrayTaskCard: View {
    // MARK: - Properties

    let task: StrayTask
    let messages: [SlackMessage]
    let isExpanded: Bool
    let onTap: () -> Void
    let onClaim: () -> Void
    let onDelete: () -> Void

    // MARK: - Initialization

    public init(
        task: StrayTask,
        messages: [SlackMessage],
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onClaim: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.messages = messages
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onClaim = onClaim
        self.onDelete = onDelete
    }

    // MARK: - Body

    public var body: some View {
        ExpandableCardWrapper(
            tintColor: Colors.strayCardTint,
            isExpanded: isExpanded,
            actions: buildActions(),
            onTap: onTap
        ) {
            // Collapsed content (always shown)
            CardHeader(
                title: task.name,
                subtitle: nil,
                chips: buildChips(),
                dueDate: task.dueDate,
                isExpanded: isExpanded
            )
        } expandedContent: {
            // Expanded content (only when expanded)
            SlackMessagesSection(messages: messages)
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
            chips.append(.agent(name: staffId, style: .stray))
        }

        // Category chip
        chips.append(.custom(
            text: task.taskCategory.rawValue,
            color: categoryColor(for: task.taskCategory)
        ))

        return chips
    }

    private func categoryColor(for category: StrayTask.TaskCategory) -> Color {
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
    let task = StrayTask(
        id: "1",
        realtorId: "realtor-1",
        name: "Update CRM with Q4 contacts",
        description: "Need to import all new contacts from networking events into CRM",
        taskCategory: .admin,
        status: .open,
        priority: 2,
        assignedStaffId: "Sarah Chen",
        dueDate: Date().addingTimeInterval(-2 * 24 * 3600),
        claimedAt: nil,
        completedAt: nil,
        createdAt: Date().addingTimeInterval(-5 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-5 * 24 * 3600),
        deletedAt: nil,
        deletedBy: nil
    )

    StrayTaskCard(
        task: task,
        messages: [],
        isExpanded: false,
        onTap: {},
        onClaim: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Expanded with Messages") {
    let task = StrayTask(
        id: "1",
        realtorId: "realtor-1",
        name: "Create Instagram reels from open house",
        description: "Edit video clips from last weekend's open house",
        taskCategory: .marketing,
        status: .open,
        priority: 3,
        assignedStaffId: nil,
        dueDate: Date().addingTimeInterval(1 * 24 * 3600),
        claimedAt: nil,
        completedAt: nil,
        createdAt: Date().addingTimeInterval(-6 * 3600),
        updatedAt: Date().addingTimeInterval(-6 * 3600),
        deletedAt: nil,
        deletedBy: nil
    )

    let messages = [
        SlackMessage(
            id: "1",
            taskId: "1",
            channelId: "C789",
            threadTs: "1699887600.901234",
            messageTs: "1699887600.901234",
            authorName: "David Kim",
            text: "Got some great clips from the open house yesterday. Lots of buyer engagement!",
            timestamp: Date().addingTimeInterval(-6 * 3600)
        ),
        SlackMessage(
            id: "2",
            taskId: "1",
            channelId: "C789",
            threadTs: "1699887600.901234",
            messageTs: "1699891200.567890",
            authorName: "Jessica Liu",
            text: "I can edit these into 3-4 short reels. Need them by end of week?",
            timestamp: Date().addingTimeInterval(-5 * 3600)
        )
    ]

    StrayTaskCard(
        task: task,
        messages: messages,
        isExpanded: true,
        onTap: {},
        onClaim: {},
        onDelete: {}
    )
    .padding()
}
