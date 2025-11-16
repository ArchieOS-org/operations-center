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
        OCListScaffold(
            onRefresh: {
                await store.refresh()
            }
        ) {
            listingsSection
            emptyStateSection
        }
        .navigationTitle("All Listings")
        .task {
            await store.fetchAllListings()
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
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.listings.isEmpty && !store.isLoading {
            OCEmptyState.noListings
                .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    AllListingsView(repository: .preview)
}
