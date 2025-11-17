//
//  TeamView.swift
//  Operations Center
//
//  Generic team view - eliminates 270 lines of duplication
//  Replaces MarketingTeamView and AdminTeamView
//

import SwiftUI
import OperationsCenterKit

/// Configuration for team views
struct TeamViewConfiguration {
    let navigationTitle: String
    let tasksSectionTitle: String
    let activitiesSectionTitle: String
    let emptyStateIcon: String
    let emptyStateTitle: String
    let emptyStateMessage: String

    static let marketing = TeamViewConfiguration(
        navigationTitle: "Marketing Team",
        tasksSectionTitle: "Marketing Tasks",
        activitiesSectionTitle: "Property Marketing",
        emptyStateIcon: "megaphone",
        emptyStateTitle: "No Marketing Tasks",
        emptyStateMessage: "Marketing tasks and campaigns will appear here"
    )

    static let admin = TeamViewConfiguration(
        navigationTitle: "Admin Team",
        tasksSectionTitle: "Admin Tasks",
        activitiesSectionTitle: "Property Admin",
        emptyStateIcon: "gearshape",
        emptyStateTitle: "No Admin Tasks",
        emptyStateMessage: "Administrative tasks will appear here"
    )
}

/// Generic team view for marketing and admin teams
struct TeamView<Store: TeamViewStore>: View {
    // MARK: - Properties

    @State private var store: Store
    private let config: TeamViewConfiguration

    // MARK: - Initialization

    init(store: Store, config: TeamViewConfiguration) {
        _store = State(initialValue: store)
        self.config = config
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
        .navigationTitle(config.navigationTitle)
        .task {
            await store.loadTasks()
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
            // Standalone Tasks
            if !store.tasks.isEmpty {
                Section(config.tasksSectionTitle) {
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

            // Property-Linked Activities
            if !store.activities.isEmpty {
                Section(config.activitiesSectionTitle) {
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
            icon: config.emptyStateIcon,
            title: config.emptyStateTitle,
            message: config.emptyStateMessage
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
