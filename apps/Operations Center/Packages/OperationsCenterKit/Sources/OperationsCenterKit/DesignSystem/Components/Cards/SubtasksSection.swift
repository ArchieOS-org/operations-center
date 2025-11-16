//
//  SubtasksSection.swift
//  OperationsCenterKit
//
//  Displays subtasks for activities in expanded state
//

import SwiftUI

/// Section displaying subtasks with completion checkboxes
struct SubtasksSection: View {
    // MARK: - Properties

    let subtasks: [Subtask]
    let onToggle: (Subtask) -> Void

    // MARK: - Body

    var body: some View {
        if !subtasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Section header with progress
                HStack {
                    Text("Subtasks")
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Text(progressText)
                        .font(Typography.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)

                // Subtasks
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(subtasks) { subtask in
                        subtaskRow(subtask)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var progressText: String {
        let completed = subtasks.filter(\.isCompleted).count
        return "\(completed)/\(subtasks.count) completed"
    }

    // MARK: - Subviews

    private func subtaskRow(_ subtask: Subtask) -> some View {
        Button {
            onToggle(subtask)
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        subtask.isCompleted ? Colors.completeAction : Color.gray.opacity(0.3)
                    )

                // Subtask name
                Text(subtask.name)
                    .font(Typography.callout)
                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                    .strikethrough(subtask.isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let mockSubtasks = [
        Subtask(
            id: "1",
            parentTaskId: "task-1",
            name: "Deep clean all rooms",
            isCompleted: true,
            completedAt: Date(),
            createdAt: Date()
        ),
        Subtask(
            id: "2",
            parentTaskId: "task-1",
            name: "Touch up paint in living room",
            isCompleted: true,
            completedAt: Date(),
            createdAt: Date()
        ),
        Subtask(
            id: "3",
            parentTaskId: "task-1",
            name: "Landscape front yard",
            isCompleted: false,
            createdAt: Date()
        ),
        Subtask(
            id: "4",
            parentTaskId: "task-1",
            name: "Stage master bedroom",
            isCompleted: false,
            createdAt: Date()
        )
    ]

    SubtasksSection(subtasks: mockSubtasks) { _ in }
    .padding()
}
