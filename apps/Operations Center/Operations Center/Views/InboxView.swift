//
//  InboxView.swift
//  Operations Center
//
//  Inbox view showing both agent tasks and activities
//  Uses explicit TaskCard and ActivityCard components
//

import OperationsCenterKit
import SwiftUI

struct InboxView: View {
    @State private var store: InboxStore

    /// Accepts pre-configured store
    init(store: InboxStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Loading inbox...")
            } else if let error = store.errorMessage {
                InboxErrorView(message: error) {
                    Task { await store.refresh() }
                }
            } else if store.tasks.isEmpty && store.activities.isEmpty {
                EmptyInboxView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Listing Tasks Section
                        if !store.activities.isEmpty {
                            sectionHeader(title: "Listings", count: store.activities.count)

                            ForEach(store.activities, id: \.task.id) { item in
                                ActivityCard(
                                    task: item.task,
                                    listing: item.listing,
                                    subtasks: item.subtasks,
                                    isExpanded: store.isExpanded(item.task.id),
                                    onTap: {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                                            store.toggleExpansion(for: item.task.id)
                                        }
                                    },
                                    onSubtaskToggle: { subtask in
                                        Task { await store.toggleSubtask(subtask) }
                                    },
                                    onClaim: {
                                        Task { await store.claimActivity(item.task) }
                                    },
                                    onDelete: {
                                        Task { await store.deleteActivity(item.task) }
                                    }
                                )
                                .id(item.task.id)
                            }
                        }

                        // Tasks Section
                        if !store.tasks.isEmpty {
                            sectionHeader(title: "Tasks", count: store.tasks.count)

                            ForEach(store.tasks, id: \.task.id) { item in
                                TaskCard(
                                    task: item.task,
                                    messages: item.messages,
                                    isExpanded: store.isExpanded(item.task.id),
                                    onTap: {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                                            store.toggleExpansion(for: item.task.id)
                                        }
                                    },
                                    onClaim: {
                                        Task { await store.claimTask(item.task) }
                                    },
                                    onDelete: {
                                        Task { await store.deleteTask(item.task) }
                                    }
                                )
                                .id(item.task.id)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .floatingActionButton {
            // Per TASK_MANAGEMENT_SPEC.md line 453: "Opens new Task modal"
            // TODO: Implement new task modal
        }
        .navigationTitle("Inbox")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchTasks()
        }
    }

    // MARK: - Subviews

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.top, 8)
    }
}

struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Tasks")
                .font(.title2)
                .fontWeight(.semibold)
            Text("New tasks will appear here")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct InboxErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview("With Mock Data") {
    let store = InboxStore(
        repository: .preview,
        initialTasks: [
            TaskWithMessages(task: AgentTask.mock1, messages: [SlackMessage.mock1]),
            TaskWithMessages(task: AgentTask.mock2, messages: [])
        ],
        initialActivities: [
            ActivityWithDetails(task: Activity.mock1, listing: Listing.mock1, subtasks: [Subtask.mock1]),
            ActivityWithDetails(task: Activity.mock2, listing: Listing.mock2, subtasks: [])
        ]
    )

    NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Empty State") {
    let store = InboxStore(repository: .preview)
    // Empty arrays via default parameters

    NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Loading State") {
    @Previewable @State var store = InboxStore(repository: .preview)
    store.isLoading = true

    return NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Error State") {
    @Previewable @State var store = InboxStore(repository: .preview)
    store.errorMessage = "Failed to connect to server"

    return NavigationStack {
        InboxView(store: store)
    }
}
