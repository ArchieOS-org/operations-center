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
    }

    // MARK: - Subviews

    private var tasksList: some View {
        List {
            strayTasksSection
            listingTasksSection
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
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
            Button("OK") {
                store.errorMessage = nil
            }
        } message: {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    private var strayTasksSection: some View {
        if !store.filteredStrayTasks.isEmpty {
            Section("Standalone Tasks") {
                ForEach(store.filteredStrayTasks, id: \.task.id) { taskWithMessages in
                    StrayTaskCard(
                        task: taskWithMessages.task,
                        messages: taskWithMessages.messages,
                        isExpanded: store.expandedTaskId == taskWithMessages.task.id,
                        onTap: {
                            store.toggleExpansion(for: taskWithMessages.task.id)
                        },
                        onClaim: {
                            Task {
                                await store.claimStrayTask(taskWithMessages.task)
                            }
                        },
                        onDelete: {
                            Task {
                                await store.deleteStrayTask(taskWithMessages.task)
                            }
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
    }

    @ViewBuilder
    private var listingTasksSection: some View {
        if !store.filteredListingTasks.isEmpty {
            Section("Property Tasks") {
                ForEach(store.filteredListingTasks, id: \.task.id) { taskWithDetails in
                    ListingTaskCard(
                        task: taskWithDetails.task,
                        listing: taskWithDetails.listing,
                        subtasks: taskWithDetails.subtasks,
                        isExpanded: store.expandedTaskId == taskWithDetails.task.id,
                        onTap: {
                            store.toggleExpansion(for: taskWithDetails.task.id)
                        },
                        onSubtaskToggle: { _ in
                            // TODO: Implement subtask toggle
                        },
                        onClaim: {
                            Task {
                                await store.claimListingTask(taskWithDetails.task)
                            }
                        },
                        onDelete: {
                            Task {
                                await store.deleteListingTask(taskWithDetails.task)
                            }
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.filteredStrayTasks.isEmpty && store.filteredListingTasks.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("No claimed tasks")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .listRowSeparator(.hidden)
        }
    }

    private var bottomControls: some View {
        HStack {
            TeamToggle(selection: $store.teamFilter)
                .padding(.leading, 16)
                .padding(.bottom, 16)

            Spacer()

            FloatingActionButton(
                systemImage: "plus",
                action: {
                    // TODO: Implement create new task
                }
            )
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllTasksView(repository: .preview)
    }
}
