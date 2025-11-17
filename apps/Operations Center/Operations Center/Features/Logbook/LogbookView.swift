//
//  LogbookView.swift
//  Operations Center
//
//  Logbook screen - archive of completed work
//  Per TASK_MANAGEMENT_SPEC.md lines 325-335
//

import SwiftUI
import OperationsCenterKit

/// Logbook screen - archive of completed work
/// Per spec: "Purpose: Archive of completed work"
/// Shows: Completed Listings (when ALL Activities are done), Completed Tasks
struct LogbookView: View {
    // MARK: - Properties

    /// Store is @Observable AND @State for projected value binding
    /// @State wrapper enables $store for Binding properties
    @State private var store: LogbookStore

    // MARK: - Initialization

    init(
        listingRepository: ListingRepositoryClient,
        taskRepository: TaskRepositoryClient
    ) {
        _store = State(initialValue: LogbookStore(
            listingRepository: listingRepository,
            taskRepository: taskRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        archiveList
    }

    // MARK: - Subviews

    private var archiveList: some View {
        List {
            completedListingsSection
            completedTasksSection
            removedItemsSection
        }
        .listStyle(.plain)
        .navigationTitle("Logbook")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchCompletedItems()
        }
        .loadingOverlay(store.isLoading && store.completedListings.isEmpty && store.completedTasks.isEmpty)
        .errorAlert($store.errorMessage)
    }

    // MARK: - Completed Listings Section

    @ViewBuilder
    private var completedListingsSection: some View {
        Section {
            if !store.completedListings.isEmpty {
                ForEach(store.completedListings) { listing in
                    NavigationLink(value: Route.listing(id: listing.id)) {
                        ListingBrowseCard(listing: listing)
                    }
                    .standardListRowInsets()
                    .listRowSeparator(.hidden)
                }
            } else if !store.isLoading {
                emptyListingsState
            }
        } header: {
            Text("Completed Listings")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var emptyListingsState: some View {
        DSEmptyState(
            icon: "checkmark.circle",
            title: "No completed listings",
            message: "Listings will appear here when all activities are complete"
        )
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Completed Tasks Section

    @ViewBuilder
    private var completedTasksSection: some View {
        Section {
            if !store.completedTasks.isEmpty {
                ForEach(store.completedTasks) { task in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(task.name)
                                .font(.headline)
                        }

                        if let description = task.description {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        HStack {
                            if let category = task.taskCategory {
                                Label(category.rawValue, systemImage: categoryIcon(for: category))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Label("Uncategorized", systemImage: "ellipsis.circle")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            if let completedAt = task.completedAt {
                                Spacer()
                                Text(completedAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            } else if !store.isLoading {
                emptyTasksState
            }
        } header: {
            Text("Completed Tasks")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var emptyTasksState: some View {
        DSEmptyState(
            icon: "checkmark.square",
            title: "No completed tasks",
            message: "Tasks will appear here when marked as done"
        )
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Removed Items Section

    @ViewBuilder
    private var removedItemsSection: some View {
        Section {
            if !store.deletedTasks.isEmpty || !store.deletedActivities.isEmpty {
                // Deleted Tasks
                ForEach(store.deletedTasks) { task in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text(task.name)
                                .font(.headline)
                        }

                        if let description = task.description {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        HStack {
                            if let category = task.taskCategory {
                                Label(category.rawValue, systemImage: categoryIcon(for: category))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Label("Uncategorized", systemImage: "ellipsis.circle")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            if let deletedAt = task.deletedAt {
                                Spacer()
                                Text("Deleted \(deletedAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                // Deleted Activities (property-specific)
                ForEach(store.deletedActivities, id: \.task.id) { activityWithDetails in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text(activityWithDetails.task.name)
                                .font(.headline)
                        }

                        // Show property address for activities
                        Text(activityWithDetails.listing.addressString)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            if let category = activityWithDetails.task.taskCategory {
                                Label(category.rawValue, systemImage: categoryIcon(for: category))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Label("Uncategorized", systemImage: "ellipsis.circle")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            if let deletedAt = activityWithDetails.task.deletedAt {
                                Spacer()
                                Text("Deleted \(deletedAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            } else if !store.isLoading {
                emptyRemovedState
            }
        } header: {
            Text("Removed")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var emptyRemovedState: some View {
        DSEmptyState(
            icon: "trash",
            title: "No removed items",
            message: "Deleted tasks and activities will appear here"
        )
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Helper Methods

    private func categoryIcon(for category: TaskCategory) -> String {
        switch category {
        case .admin: return "gearshape"
        case .marketing: return "megaphone"
        case .photo: return "camera"
        case .staging: return "sofa"
        case .inspection: return "checkmark.seal"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LogbookView(
            listingRepository: .preview,
            taskRepository: .preview
        )
    }
}
