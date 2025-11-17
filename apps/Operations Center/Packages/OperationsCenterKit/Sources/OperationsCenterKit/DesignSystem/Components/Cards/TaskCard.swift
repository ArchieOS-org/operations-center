//
//  TaskCard.swift
//  OperationsCenterKit
//
//  Orange accent, no border, Slack messages first
//  First-class citizen for general tasks
//

import SwiftUI

/// Card for displaying tasks (general agent tasks)
public struct TaskCard: View {
    // MARK: - Properties

    let task: AgentTask
    let messages: [SlackMessage]
    let isExpanded: Bool
    let onTap: () -> Void

    // MARK: - Initialization

    public init(
        task: AgentTask,
        messages: [SlackMessage],
        isExpanded: Bool,
        onTap: @escaping () -> Void
    ) {
        self.task = task
        self.messages = messages
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        ExpandableCardWrapper(
            tintColor: Colors.surfaceAgentTaskTinted,
            isExpanded: isExpanded,
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

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Assigned agent chip
        if let staffId = task.assignedStaffId {
            chips.append(.agent(name: staffId, style: .agentTask))
        }

        // Category chip
        chips.append(.custom(
            text: task.taskCategory.rawValue,
            color: categoryColor(for: task.taskCategory)
        ))

        return chips
    }

    private func categoryColor(for category: AgentTask.TaskCategory) -> Color {
        switch category {
        case .admin: return Colors.categoryAdmin
        case .marketing: return Colors.categoryMarketing
        case .photo: return Colors.categoryPhoto
        case .staging: return Colors.categoryStaging
        case .inspection: return Colors.categoryInspection
        case .other: return Colors.categoryOther
        }
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    TaskCard(
        task: AgentTask.mock1,
        messages: [],
        isExpanded: false,
        onTap: {}
    )
    .padding()
}

#Preview("Expanded with Messages") {
    let messages = [
        SlackMessage.mock1,
        SlackMessage.mock2
    ]

    TaskCard(
        task: AgentTask.mock2,
        messages: messages,
        isExpanded: true,
        onTap: {}
    )
    .padding()
}
