//
//  AllTasksView.swift
//  Operations Center
//
//  All Tasks screen - shows all claimed tasks system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 286-305
//

import SwiftUI
import OperationsCenterKit

/// All Tasks screen - all claimed tasks across entire system
/// Per spec: "All claimed Tasks system-wide (standalone + assigned to listings)"
/// Features: Expandable cards, Marketing/Admin/All toggle, Add button, Action bar
struct AllTasksView: View {
    // MARK: - Properties

    @State private var store: AllTasksStore

    // MARK: - Initialization

    init(repository: TaskRepositoryClient) {
        _store = State(initialValue: AllTasksStore(repository: repository))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            tasksList
            bottomControls
        }
        .overlay(alignment: .bottom) {
            // Floating context menu - appears at screen bottom when card is expanded
            if let expandedId = store.expandedTaskId {
                Group {
                    if let task = findExpandedTask(id: expandedId) {
                        DSContextMenu(actions: buildTaskActions(for: task))
                    } else if let activity = findExpandedActivity(id: expandedId) {
                        DSContextMenu(actions: buildActivityActions(for: activity))
                    }
                }
                .padding(.bottom, Spacing.lg)
                .padding(.horizontal, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedTaskId)
    }

    // MARK: - Helpers

    private func findExpandedTask(id: String) -> AgentTask? {
        store.filteredTasks.first(where: { $0.task.id == id })?.task
    }

    private func findExpandedActivity(id: String) -> Activity? {
        store.filteredActivities.first(where: { $0.task.id == id })?.task
    }

    private func buildTaskActions(for task: AgentTask) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
            onClaim: {
                Task { await store.claimTask(task) }
            },
            onDelete: {
                Task { await store.deleteTask(task) }
            }
        )
    }

    private func buildActivityActions(for activity: Activity) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
            onClaim: {
                Task { await store.claimActivity(activity) }
            },
            onDelete: {
                Task { await store.deleteActivity(activity) }
            }
        )
    }

    // MARK: - Subviews

    private var tasksList: some View {
        List {
            tasksSection
            activitiesSection
            emptyStateSection
        }
        .listStyle(.plain)
        .navigationTitle("All Tasks")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchAllTasks()
        }
        .loadingOverlay(store.isLoading)
        .errorAlert($store.errorMessage)
    }

    @ViewBuilder
    private var tasksSection: some View {
        if !store.filteredTasks.isEmpty {
            Section("Standalone Tasks") {
                ForEach(store.filteredTasks, id: \.task.id) { taskWithMessages in
                    TaskCard(
                        task: taskWithMessages.task,
                        messages: taskWithMessages.messages,
                        isExpanded: store.expandedTaskId == taskWithMessages.task.id,
                        onTap: {
                            store.toggleExpansion(for: taskWithMessages.task.id)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var activitiesSection: some View {
        if !store.filteredActivities.isEmpty {
            Section("Property Tasks") {
                ForEach(store.filteredActivities, id: \.task.id) { taskWithDetails in
                    ActivityCard(
                        task: taskWithDetails.task,
                        listing: taskWithDetails.listing,
                        isExpanded: store.expandedTaskId == taskWithDetails.task.id,
                        onTap: {
                            store.toggleExpansion(for: taskWithDetails.task.id)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.filteredTasks.isEmpty && store.filteredActivities.isEmpty {
            DSEmptyState(
                icon: "checkmark.circle",
                title: "No claimed tasks",
                message: "Tasks will appear here when you claim them"
            )
            .listRowSeparator(.hidden)
        }
    }

    private var bottomControls: some View {
        HStack {
            TeamToggle(selection: $store.teamFilter)
                .padding(.leading, Spacing.md)
                .padding(.bottom, Spacing.md)

            Spacer()

            FloatingActionButton(
                systemImage: "plus",
                action: {}
            )
            .padding(.trailing, Spacing.md)
            .padding(.bottom, Spacing.md)
            .offset(y: store.expandedTaskId != nil ? 100 : 0)
            .opacity(store.expandedTaskId != nil ? 0 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedTaskId)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllTasksView(repository: .preview)
    }
}
