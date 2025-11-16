//
//  MyTasksView.swift
//  Operations Center
//
//  View for My Tasks screen
//  Per TASK_MANAGEMENT_SPEC.md lines 172-194
//

import SwiftUI
import OperationsCenterKit

/// My Tasks screen
///
/// Per TASK_MANAGEMENT_SPEC.md:
/// - "See all Tasks I've claimed" (line 173)
/// - "Add Button: Creates new Task inline at bottom" (line 185)
/// - "Bottom Action Bar: Claim (press/hold for assignment), User Type toggle" (line 189)
/// - "Toggle: None (only shows MY tasks)" (line 193)
struct MyTasksView: View {
    // MARK: - State

    @State private var store: MyTasksStore
    @State private var showingNewTask = false
    @State private var newTaskTitle = ""

    // MARK: - Initialization

    /// Initialize view with repository injection
    /// Following Context7 @State initialization pattern
    init(repository: TaskRepositoryClient) {
        _store = State(initialValue: MyTasksStore(repository: repository))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Task list
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.tasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .floatingActionButton {
            // Per spec line 185: "Creates new Task inline at bottom"
            showingNewTask = true
        }
        .navigationTitle("My Tasks")
        .task {
            await store.fetchMyTasks()
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(store.tasks) { task in
                    taskCard(for: task)
                }

                // New task creation inline
                // Per spec line 186: "No action bar shown during creation"
                if showingNewTask {
                    newTaskCard
                }
            }
            .padding()
        }
    }

    // MARK: - Task Card

    @ViewBuilder
    private func taskCard(for task: StrayTask) -> some View {
        let isExpanded = store.expandedTaskId == task.id

        StrayTaskCard(
            task: task,
            messages: [], // TODO: Load Slack messages
            isExpanded: isExpanded,
            onTap: {
                store.toggleExpansion(for: task.id)
            },
            onClaim: {
                Task {
                    await store.claimTask(task)
                }
            },
            onDelete: {
                Task {
                    await store.deleteTask(task)
                }
            }
        )
        .animation(.spring(duration: 0.3, bounce: 0.1), value: isExpanded)
    }

    // MARK: - New Task Card

    private var newTaskCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("New Task")
                .font(Typography.cardTitle)
                .foregroundStyle(.secondary)

            TextField("Task title", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingNewTask = false
                    newTaskTitle = ""
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Create") {
                    // TODO: Create task logic
                    showingNewTask = false
                    newTaskTitle = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            VStack(spacing: Spacing.xs) {
                Text("No Tasks")
                    .font(Typography.title1)

                Text("You haven't claimed any tasks yet")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

// MARK: - Preview

#Preview {
    MyTasksView(repository: .preview)
}
