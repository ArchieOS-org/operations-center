//
//  InboxView.swift
//  Operations Center
//
//  Inbox view showing both stray and listing tasks
//  Uses explicit StrayTaskCard and ListingTaskCard components
//

import SwiftUI
import OperationsCenterKit

struct InboxView: View {
    @State private var store: InboxStore

    /// Primary init - accepts pre-configured store (for previews/testing)
    init(store: InboxStore) {
        _store = State(initialValue: store)
    }

    /// Convenience init for production - creates store with live repository
    /// Checks for --use-preview-data flag from Xcode scheme
    init() {
        let usePreviewData = CommandLine.arguments.contains("--use-preview-data")
        self.init(store: InboxStore(repository: usePreviewData ? .preview : .live))
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Loading inbox...")
            } else if let error = store.errorMessage {
                InboxErrorView(message: error) {
                    Task { await store.refresh() }
                }
            } else if store.strayTasks.isEmpty && store.listingTasks.isEmpty {
                EmptyInboxView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Listing Tasks Section
                        if !store.listingTasks.isEmpty {
                            sectionHeader(title: "Listings", count: store.listingTasks.count)

                            ForEach(store.listingTasks, id: \.task.id) { item in
                                ListingTaskCard(
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
                                        Task { await store.claimListingTask(item.task) }
                                    },
                                    onDelete: {
                                        Task { await store.deleteListingTask(item.task) }
                                    }
                                )
                                .id(item.task.id)
                            }
                        }

                        // Stray Tasks Section
                        if !store.strayTasks.isEmpty {
                            sectionHeader(title: "Stray Tasks", count: store.strayTasks.count)

                            ForEach(store.strayTasks, id: \.task.id) { item in
                                StrayTaskCard(
                                    task: item.task,
                                    messages: item.messages,
                                    isExpanded: store.isExpanded(item.task.id),
                                    onTap: {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                                            store.toggleExpansion(for: item.task.id)
                                        }
                                    },
                                    onClaim: {
                                        Task { await store.claimStrayTask(item.task) }
                                    },
                                    onDelete: {
                                        Task { await store.deleteStrayTask(item.task) }
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
        initialStrayTasks: [
            (StrayTask.mock1, [SlackMessage.mock1]),
            (StrayTask.mock2, [])
        ],
        initialListingTasks: [
            (ListingTask.mock1, Listing.mock1, [Subtask.mock1]),
            (ListingTask.mock2, Listing.mock2, [])
        ]
    )

    return NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Empty State") {
    let store = InboxStore(repository: .preview)
    // Empty arrays via default parameters

    return NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Loading State") {
    let store = InboxStore(repository: .preview)
    store.isLoading = true

    return NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Error State") {
    let store = InboxStore(repository: .preview)
    store.errorMessage = "Failed to connect to server"

    return NavigationStack {
        InboxView(store: store)
    }
}
