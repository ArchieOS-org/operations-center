//
//  AdminTeamView.swift
//  Operations Center
//
//  Admin team view - shows all admin tasks/activities system-wide
//

import SwiftUI
import OperationsCenterKit

struct AdminTeamView: View {
    // MARK: - Properties

    @State private var store: AdminTeamStore

    // MARK: - Initialization

    init(repository: TaskRepositoryClient) {
        _store = State(initialValue: AdminTeamStore(taskRepository: repository))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if store.isLoading {
                ProgressView()
            } else if store.tasks.isEmpty && store.activities.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .navigationTitle("Admin Team")
        .task {
            await store.loadAdminTasks()
        }
        .overlay(alignment: .bottom) {
            if let expandedId = store.expandedTaskId {
                contextMenu(for: expandedId)
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedTaskId)
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        List {
            // Standalone Admin Tasks
            if !store.tasks.isEmpty {
                Section("Admin Tasks") {
                    ForEach(store.tasks, id: \.task.id) { taskWithMessages in
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

            // Property-Linked Admin Activities
            if !store.activities.isEmpty {
                Section("Property Admin") {
                    ForEach(store.activities, id: \.task.id) { activityWithDetails in
                        ActivityCard(
                            task: activityWithDetails.task,
                            listing: activityWithDetails.listing,
                            isExpanded: store.expandedTaskId == activityWithDetails.task.id,
                            onTap: {
                                store.toggleExpansion(for: activityWithDetails.task.id)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .standardListRowInsets()
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var emptyState: some View {
        DSEmptyState(
            icon: "gearshape",
            title: "No Admin Tasks",
            message: "Administrative tasks will appear here"
        )
    }

    /// Builds a bottom-aligned context menu for the task or property activity matching the provided identifier.
    /// - Parameter taskId: The identifier of the task to show actions for.
    /// - Returns: A view containing a bottom context menu with actions for the matching task or activity, or an empty view if no matching item is found.
    @ViewBuilder
    private func contextMenu(for taskId: String) -> some View {
        // Find the task or activity
        if let taskWithMessages = store.tasks.first(where: { $0.task.id == taskId }) {
            DSContextMenu(actions: buildTaskActions(for: taskWithMessages.task))
                .padding(.bottom, Spacing.lg)
                .padding(.horizontal, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if let activityWithDetails = store.activities.first(where: { $0.task.id == taskId }) {
            DSContextMenu(actions: buildActivityActions(for: activityWithDetails.task))
                .padding(.bottom, Spacing.lg)
                .padding(.horizontal, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Builds the context menu actions for a standalone admin task.
    /// - Parameter task: The `AgentTask` to produce actions for.
    /// - Returns: An array of `DSContextAction` providing actions to claim or delete the given task; invoking these actions performs the corresponding asynchronous store operations.

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

    /// Creates the context menu actions for a property-linked admin activity.
    /// - Parameters:
    ///   - activity: The activity to build actions for; actions will operate on this activity.
    /// - Returns: An array of `DSContextAction` including claim and delete actions for the provided activity.
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminTeamView(repository: .preview)
    }
}