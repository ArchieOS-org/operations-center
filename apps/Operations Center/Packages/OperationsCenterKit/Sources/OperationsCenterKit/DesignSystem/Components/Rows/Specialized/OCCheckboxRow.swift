//
//  OCCheckboxRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Reusable checkbox row for Subtask and similar items
public struct OCCheckboxRow: View {
    private let text: String
    private let isChecked: Bool
    private let onToggle: () -> Void

    public init(
        text: String,
        isChecked: Bool,
        onToggle: @escaping () -> Void
    ) {
        self.text = text
        self.isChecked = isChecked
        self.onToggle = onToggle
    }

    public var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: Spacing.md) {
                // Checkbox
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isChecked ? Colors.actionPositive : Color.gray.opacity(0.3)
                    )

                // Text with strikethrough when checked
                Text(text)
                    .font(Typography.callout)
                    .foregroundStyle(isChecked ? Color.secondary : Color.primary)
                    .strikethrough(isChecked)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Convenience Initializer for Subtask

extension OCCheckboxRow {
    /// Initialize from a Subtask model
    public init(
        subtask: Subtask,
        onToggle: @escaping () -> Void
    ) {
        self.text = subtask.name
        self.isChecked = subtask.isCompleted
        self.onToggle = onToggle
    }
}