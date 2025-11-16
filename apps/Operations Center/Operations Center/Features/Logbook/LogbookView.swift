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

    @State private var store: LogbookStore
    @State private var navigationPath: [Route] = []

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
        NavigationStack(path: $navigationPath) {
            archiveList
                .navigationDestination(for: Route.self) { _ in
                    // Route to detail views (listings only for now)
                    EmptyView()
                }
        }
    }

    // MARK: - Subviews

    private var archiveList: some View {
        List {
            completedListingsSection
            completedTasksSection
        }
        .listStyle(.plain)
        .navigationTitle("Logbook")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchCompletedItems()
        }
        .overlay {
            if store.isLoading && store.completedListings.isEmpty && store.completedTasks.isEmpty {
                ProgressView()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") {
                store.errorMessage = nil
            }
        } message: {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Completed Listings Section

    @ViewBuilder
    private var completedListingsSection: some View {
        Section {
            if !store.completedListings.isEmpty {
                ForEach(store.completedListings) { listing in
                    ListingBrowseCard(
                        listing: listing,
                        onTap: {
                            // Navigate to listing detail (not yet wired up)
                            navigationPath.append(.listing(id: listing.id))
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No completed listings")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Listings will appear here when all activities are complete")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Completed Tasks Section

    @ViewBuilder
    private var completedTasksSection: some View {
        Section {
            if !store.completedTasks.isEmpty {
                ForEach(store.completedTasks) { task in
                    VStack(alignment: .leading, spacing: 4) {
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
                            Label(task.taskCategory.rawValue, systemImage: categoryIcon(for: task.taskCategory))
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                            if let completedAt = task.completedAt {
                                Spacer()
                                Text(completedAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
        VStack(spacing: 8) {
            Image(systemName: "checkmark.square")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No completed tasks")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Tasks will appear here when marked as done")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    private func categoryIcon(for category: StrayTask.TaskCategory) -> String {
        switch category {
        case .admin: return "gearshape"
        case .marketing: return "megaphone"
        case .photo: return "camera"
        case .staging: return "house"
        case .inspection: return "checklist"
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
