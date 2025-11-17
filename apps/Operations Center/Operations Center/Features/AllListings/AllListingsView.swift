//
//  AllListingsView.swift
//  Operations Center
//
//  All Listings screen - shows all listings system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 307-322
//

import SwiftUI
import OperationsCenterKit

/// All Listings screen - browse all listings to claim Activities
/// Per spec: "All Listings across system (acknowledged and unacknowledged)"
/// Features: Collapsed cards only, click-to-navigate
struct AllListingsView: View {
    // MARK: - Properties

    @State private var store: AllListingsStore

    // MARK: - Initialization

    init(repository: ListingRepositoryClient) {
        _store = State(initialValue: AllListingsStore(repository: repository))
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
        .navigationTitle("All Listings")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchAllListings()
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
                        ListingCollapsedContent(listing: listing)
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
                title: "No listings",
                message: "Listings will appear here when they're added to the system"
            )
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    AllListingsView(repository: .preview)
}
