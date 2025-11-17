//
//  MyListingsView.swift
//  Operations Center
//
//  My Listings screen - shows listings where user has claimed activities
//  Per TASK_MANAGEMENT_SPEC.md lines 197-213
//

import SwiftUI
import OperationsCenterKit

/// My Listings screen - see all listings where I've claimed activities
/// Per spec: "Listings where user has claimed at least one Activity"
/// Features: Collapsed cards only, click-to-navigate
struct MyListingsView: View {
    // MARK: - Properties

    @State private var store: MyListingsStore

    // MARK: - Initialization

    init(listingRepository: ListingRepositoryClient, taskRepository: TaskRepositoryClient) {
        _store = State(initialValue: MyListingsStore(
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
            listingsSection
            emptyStateSection
        }
        .navigationTitle("My Listings")
        .task {
            await store.fetchMyListings()
        }
        .overlay {
            if store.isLoading {
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

    // MARK: - Subviews

    @ViewBuilder
    private var listingsSection: some View {
        if !store.listings.isEmpty {
            Section {
                ForEach(store.listings, id: \.id) { listing in
                    NavigationLink(value: Route.listing(id: listing.id)) {
                        OCListingRow(listing: listing)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.listings.isEmpty && !store.isLoading {
            OCEmptyState(
                title: "No listings with claimed activities",
                systemImage: "house.circle",
                description: "Listings will appear here when you claim activities"
            )
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    MyListingsView(
        listingRepository: .preview,
        taskRepository: .preview
    )
}
