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

    @ViewBuilder
    private var listingsSection: some View {
        if !store.listings.isEmpty {
            Section {
                ForEach(store.listings, id: \.id) { listing in
                    NavigationLink(value: Route.listing(id: listing.id)) {
                        ListingBrowseCard(
                            listing: listing,
                            onTap: {}
                        )
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.listings.isEmpty && !store.isLoading {
            VStack(spacing: 16) {
                Image(systemName: "house.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("No listings")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Listings will appear here when they're added to the system")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    AllListingsView(repository: .preview)
}
