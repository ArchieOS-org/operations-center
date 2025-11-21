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
    /// Store is @Observable - SwiftUI tracks changes automatically
    /// No @State wrapper needed for @Observable objects
    let store: InboxStore

    /// Accepts pre-configured store
    init(store: InboxStore) {
        self.store = store
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Loading inbox...")
            } else if let error = store.errorMessage {
                DSErrorState(
                    message: error,
                    retryAction: {
                        Task { await store.refresh() }
                    }
                )
            } else if store.tasks.isEmpty && store.listings.isEmpty {
                DSEmptyState(
                    icon: "tray",
                    title: "No Tasks",
                    message: "New tasks will appear here"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        // Listings Section
                        if !store.listings.isEmpty {
                            sectionHeader(title: "Listings", count: store.listings.count)

                            ForEach(store.listings) { item in
                                ListingCard(
                                    listing: item.listing,
                                    realtor: item.realtor,
                                    tasks: item.activities,
                                    notes: item.notes,
                                    noteInputText: Binding(
                                        get: { store.listingNoteInputs[item.listing.id] ?? "" },
                                        set: { store.listingNoteInputs[item.listing.id] = $0 }
                                    ),
                                    isExpanded: store.isExpanded(item.listing.id),
                                    onTap: {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                                            store.toggleExpansion(for: item.listing.id)
                                        }
                                    },
                                    onTaskTap: { _ in
                                        // Activity tap - could navigate to detail or expand inline
                                    },
                                    onSubmitNote: {
                                        store.submitNote(for: item.listing.id)
                                    }
                                )
                                .id(item.listing.id)
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
        .floatingActionButton(isHidden: store.expandedTaskId != nil) {
            // Per TASK_MANAGEMENT_SPEC.md line 453: "Opens new Task modal"
            // NOTE: Implement new task modal
        }
        .overlay(alignment: .bottom) {
            // Floating context menu - appears at screen bottom when card is expanded
            if let expandedId = store.expandedTaskId {
                Group {
                    if let task = findExpandedTask(id: expandedId) {
                        DSContextMenu(actions: buildTaskActions(for: task))
                    } else if let listing = findExpandedListing(id: expandedId) {
                        DSContextMenu(actions: buildListingActions(for: listing))
                    }
                }
                .padding(.bottom, Spacing.lg)
                .padding(.horizontal, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedTaskId)
        .navigationTitle("Inbox")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchTasks()
        }
    }

    // MARK: - Helpers

    private func findExpandedTask(id: String) -> AgentTask? {
        store.tasks.first(where: { $0.task.id == id })?.task
    }

    private func findExpandedListing(id: String) -> ListingWithDetails? {
        store.listings.first(where: { $0.listing.id == id })
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

    private func buildListingActions(for listingWithDetails: ListingWithDetails) -> [DSContextAction] {
        [
            DSContextAction(
                title: "Acknowledge",
                systemImage: "checkmark.circle",
                action: {
                    Task { await store.acknowledgeListing(listingWithDetails.listing.id) }
                }
            ),
            DSContextAction(
                title: "Delete",
                systemImage: "trash",
                role: .destructive,
                action: {
                    // Delete all activities in this listing
                    for activity in listingWithDetails.activities {
                        Task { await store.deleteActivity(activity) }
                    }
                }
            )
        ]
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
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.top, Spacing.sm)
    }
}

#Preview("With Mock Data") {
    let store = InboxStore.makePreview(
        supabase: supabase,
        initialTasks: [
            TaskWithMessages(task: AgentTask.mock1, messages: [SlackMessage.mock1]),
            TaskWithMessages(task: AgentTask.mock2, messages: [])
        ],
        initialListings: [
            ListingWithDetails(
                listing: Listing.mock1,
                realtor: Realtor.mock1,
                activities: [Activity.mock1, Activity.mock2],
                notes: [ListingNote.mock1, ListingNote.mock2]
            ),
            ListingWithDetails(
                listing: Listing.mock2,
                realtor: Realtor.mock2,
                activities: [Activity.mock3],
                notes: [ListingNote.mock3]
            )
        ]
    )

    NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Empty State") {
    let store = InboxStore.makePreview(supabase: supabase)

    NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Loading State") {
    let store = {
        let s = InboxStore.makePreview(supabase: supabase)
        s.isLoading = true
        return s
    }()

    return NavigationStack {
        InboxView(store: store)
    }
}

#Preview("Error State") {
    let store = {
        let s = InboxStore.makePreview(supabase: supabase)
        s.errorMessage = "Failed to connect to server"
        return s
    }()

    return NavigationStack {
        InboxView(store: store)
    }
}
