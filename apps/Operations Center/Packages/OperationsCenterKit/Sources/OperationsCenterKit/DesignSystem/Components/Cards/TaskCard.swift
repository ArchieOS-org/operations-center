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
    let assigneeName: String?
    let onTap: () -> Void

    // MARK: - Initialization

    public init(
        task: AgentTask,
        messages: [SlackMessage],
        isExpanded: Bool,
        assigneeName: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.task = task
        self.messages = messages
        self.isExpanded = isExpanded
        self.assigneeName = assigneeName
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
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Slack messages (if any)
                if !messages.isEmpty {
                    SlackMessagesSection(messages: messages)
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
        if let name = assigneeName {
            chips.append(.agent(name: name, style: .agentTask))
        }

        // Category chip (if categorized)
        if let category = task.taskCategory {
            chips.append(.custom(
                text: category.rawValue,
                color: categoryColor(for: category)
            ))
        }

        return chips
    }

    private func categoryColor(for category: TaskCategory) -> Color {
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
        assigneeName: "Sarah Johnson",
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
        assigneeName: "Alex Chen",
        onTap: {}
    )
    .padding()
}
