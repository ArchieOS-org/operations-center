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
        OCListScaffold(
            onRefresh: {
                await store.refresh()
            }
        ) {
            completedListingsSection
            completedTasksSection
            emptyStateSection
        }
        .navigationTitle("Logbook")
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

    // MARK: - Sections

    @ViewBuilder
    private var completedListingsSection: some View {
        if !store.completedListings.isEmpty {
            Section {
                ForEach(store.completedListings) { listing in
                    NavigationLink(value: Route.listing(id: listing.id)) {
                        OCListingRow(listing: listing)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                OCSectionHeader(
                    title: "Completed Listings",
                    count: store.completedListings.count
                )
            }
        }
    }

    @ViewBuilder
    private var completedTasksSection: some View {
        if !store.completedTasks.isEmpty {
            Section {
                ForEach(store.completedTasks) { task in
                    OCTaskRow(task: task)
                }
            } header: {
                OCSectionHeader(
                    title: "Completed Tasks",
                    count: store.completedTasks.count
                )
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.completedListings.isEmpty && store.completedTasks.isEmpty && !store.isLoading {
            OCEmptyState.noActivity
                .listRowSeparator(.hidden)
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
