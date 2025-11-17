//
//  OCTaskRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// General task row for standalone tasks. Replaces TaskCard header and card chrome.
public struct OCTaskRow<ExpandedContent: View>: View {
    private let task: AgentTask
    private let agentName: String?
    private let isExpanded: Bool
    private let onTap: (() -> Void)?
    private let expandedContent: ExpandedContent?

    public init(
        task: AgentTask,
        agentName: String? = nil,
        isExpanded: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.task = task
        self.agentName = agentName
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
                    .fill(task.status.statusColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Primary: Task name
                    Text(task.name)
                        .font(Typography.cardTitle)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    // Chips row
                    HStack(spacing: Spacing.sm) {
                        // Agent name chip (if present)
                        if let agentName {
                            DSChip(agentName: agentName, style: .agentTask)
                        }

                        // Category chip
                        DSChip(
                            text: task.taskCategory.displayName,
                            color: Colors.accentAgentTask
                        )

                        Spacer(minLength: 0)
                    }
                }
            }
        } expandedContent: {
            // Expanded content (SlackMessagesSection, etc.)
            if let expandedContent {
                expandedContent
                    .padding(.top, Spacing.sm)
            }
        } accessory: {
            // Due date chip as trailing accessory when present
            if let dueDate = task.dueDate {
                DSChip(date: dueDate)
            }
        }
    }
}

// MARK: - Convenience Initializer

extension OCTaskRow where ExpandedContent == EmptyView {
    /// Initialize without expanded content
    public init(
        task: AgentTask,
        agentName: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.task = task
        self.agentName = agentName
        self.isExpanded = false
        self.onTap = onTap
        self.expandedContent = nil
    }
}