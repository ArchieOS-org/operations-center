//
//  MarketingTeamView.swift
//  Operations Center
//
//  Marketing team view - shows all marketing tasks/activities system-wide
//

import SwiftUI
import OperationsCenterKit

struct MarketingTeamView: View {
    // MARK: - Properties

    @State private var store: MarketingTeamStore

    // MARK: - Initialization

    init(repository: TaskRepositoryClient) {
        _store = State(initialValue: MarketingTeamStore(taskRepository: repository))
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
        .navigationTitle("Marketing Team")
        .task {
            await store.loadMarketingTasks()
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
            // Standalone Marketing Tasks
            if !store.tasks.isEmpty {
                Section("Marketing Tasks") {
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

            // Property-Linked Marketing Activities
            if !store.activities.isEmpty {
                Section("Property Marketing") {
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
            icon: "megaphone",
            title: "No Marketing Tasks",
            message: "Marketing tasks and campaigns will appear here"
        )
    }

    /// Presents a bottom-aligned context menu for the task or activity matching `taskId`.
    /// - Parameters:
    ///   - taskId: The identifier of the task or activity to display actions for.
    /// - Returns: A view containing a context menu with actions for the matching task or activity, or an empty view if no match is found.
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

    /// Creates the context menu actions for the given marketing task.
    /// - Parameter task: The `AgentTask` to create actions for.
    /// - Returns: An array of `DSContextAction` containing claim and delete actions for the provided task.

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

    /// Builds the context menu actions for a property marketing activity.
    /// - Returns: An array of `DSContextAction` configured with handlers that claim or delete the provided activity.
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
        MarketingTeamView(repository: .preview)
    }
}