//
//  ExpandableCardWrapper.swift
//  OperationsCenterKit
//
//  Wraps any card content with expansion state and action bar
//  Per TASK_MANAGEMENT_SPEC.md lines 469-482: Context Menu floats at bottom when card expanded
//

import SwiftUI

/// Wraps card content with expansion state and contextual action bar
///
/// Per TASK_MANAGEMENT_SPEC.md:
/// - "Floats at bottom middle of screen, only when a card is expanded" (line 470)
/// - "Contents: Contextual buttons based on card type" (line 477)
/// - "Paired with card type (Task, Activity, Listing), NOT screen" (line 480)
///
/// Context7 pattern: Generic view with @ViewBuilder closure
struct ExpandableCardWrapper<CollapsedContent: View, ExpandedContent: View>: View {
    // MARK: - Properties

    let tintColor: Color
    let isExpanded: Bool
    let onTap: () -> Void

    @ViewBuilder let collapsedContent: () -> CollapsedContent
    @ViewBuilder let expandedContent: () -> ExpandedContent

    // MARK: - Initialization

    init(
        tintColor: Color,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder collapsedContent: @escaping () -> CollapsedContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        self.tintColor = tintColor
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.collapsedContent = collapsedContent
        self.expandedContent = expandedContent
    }

    // MARK: - Body

    var body: some View {
        // The card itself using existing CardBase system
        // Action bar is now rendered at screen-level via .overlay() in parent views
        CardBase(
            tintColor: tintColor,
            isExpanded: isExpanded,
            onTap: onTap
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Always show collapsed content
                collapsedContent()

                // Show expanded content when expanded
                if isExpanded {
                    expandedContent()
                }
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: isExpanded)
    }
}

// MARK: - Convenience Initializer for Same Content

extension ExpandableCardWrapper where CollapsedContent == ExpandedContent {
    /// Initializer when collapsed and expanded content are the same
    init(
        tintColor: Color,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> CollapsedContent
    ) {
        self.init(
            tintColor: tintColor,
            isExpanded: isExpanded,
            onTap: onTap,
            collapsedContent: content,
            expandedContent: content
        )
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    ExpandableCardWrapper(
        tintColor: Colors.agentTaskCardTint,
        isExpanded: false,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Update CRM with Q4 contacts")
                .font(Typography.cardTitle)
            Text("Sarah Chen")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
        }
    } expandedContent: {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes: Follow up on enterprise leads")
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}

#Preview("Expanded") {
    ExpandableCardWrapper(
        tintColor: Colors.agentTaskCardTint,
        isExpanded: true,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Update CRM with Q4 contacts")
                .font(Typography.cardTitle)
            Text("Sarah Chen")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
        }
    } expandedContent: {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes: Follow up on enterprise leads")
                .font(Typography.body)
                .foregroundStyle(.secondary)

            Text("Status: In Progress")
                .font(Typography.caption1)
                .foregroundStyle(.tertiary)
        }
    }
    .padding()
}
