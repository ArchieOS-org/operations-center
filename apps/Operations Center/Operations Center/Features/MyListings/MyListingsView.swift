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
        listingsList
    }

    // MARK: - Subviews

    private var listingsList: some View {
        List {
            listingsSection
            emptyStateSection
        }
        .listStyle(.plain)
        .navigationTitle("My Listings")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchMyListings()
        }
        .loadingOverlay(store.isLoading)
        .errorAlert($store.errorMessage)
    }

    @ViewBuilder
    private var listingsSection: some View {
        if !store.listings.isEmpty {
            Section {
                ForEach(store.listings, id: \.id) { listing in
                    NavigationLink(value: Route.listing(id: listing.id)) {
                        ListingBrowseCard(listing: listing)
                    }
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.listings.isEmpty && !store.isLoading {
            DSEmptyState(
                icon: "house.circle",
                title: "No listings with claimed activities",
                message: "Listings will appear here when you claim activities"
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
