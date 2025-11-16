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
            OCListScaffold(
                onRefresh: {
                    await store.fetchMyTasks()
                }
            ) {
                if store.isLoading && store.tasks.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .listRowSeparator(.hidden)
                } else if store.tasks.isEmpty && !showingNewTask {
                    OCEmptyState.noTasks
                        .listRowSeparator(.hidden)
                } else {
                    tasksSection
                    if showingNewTask {
                        newTaskSection
                    }
                }
            }
            .floatingActionButton(isHidden: store.expandedTaskId != nil) {
                // Per spec line 185: "Creates new Task inline at bottom"
                showingNewTask = true
            }
        }
        .overlay(alignment: .bottom) {
            // Floating context menu - appears at screen bottom when card is expanded
            // Per spec line 470: "Floats at bottom middle of screen, only when a card is expanded"
            if let expandedId = store.expandedTaskId,
               let task = store.tasks.first(where: { $0.id == expandedId }) {
                DSContextMenu(actions: buildContextActions(for: task))
                    .padding(.bottom, Spacing.lg)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedTaskId)
        .navigationTitle("My Tasks")
        .alert("Error", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") {
                store.errorMessage = nil
            }
        } message: {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await store.fetchMyTasks()
        }
    }

    // MARK: - Tasks Section

    @ViewBuilder
    private var tasksSection: some View {
        if !store.tasks.isEmpty {
            Section {
                ForEach(store.tasks) { task in
                    OCTaskRow(task: task)
                        .onTapGesture {
                            store.toggleExpansion(for: task.id)
                        }
                }
            } header: {
                OCSectionHeader(
                    title: "My Tasks",
                    count: store.tasks.count
                )
            }
        }
    }

    // MARK: - New Task Section

    @ViewBuilder
    private var newTaskSection: some View {
        Section {
            newTaskCard
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } header: {
            OCSectionHeader(title: "New Task")
        }
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
                    // NOTE: Create task logic
                    showingNewTask = false
                    newTaskTitle = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTaskTitle.isEmpty)
            }
        }
        .padding()
        .background(Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Context Actions

    private func buildContextActions(for task: AgentTask) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
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
    }

}

// MARK: - Preview

#Preview {
    MyTasksView(repository: .preview)
}
