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

    // MARK: - Helper Methods

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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminTeamView(repository: .preview)
    }
}
