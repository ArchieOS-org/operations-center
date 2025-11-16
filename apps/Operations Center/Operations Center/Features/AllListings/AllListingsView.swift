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
/// Features: Collapsed cards only, click-to-navigate, Marketing/Admin/All toggle
struct AllListingsView: View {
    // MARK: - Properties

    @State private var store: AllListingsStore
    @State private var navigationPath: [Route] = []

    // MARK: - Initialization

    init(repository: ListingRepositoryClient) {
        _store = State(initialValue: AllListingsStore(repository: repository))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomLeading) {
                listingsList
                teamToggle
            }
        }
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
    private var listingsSection: some View {
        if !store.filteredListings.isEmpty {
            Section {
                ForEach(store.filteredListings, id: \.id) { listing in
                    ListingBrowseCard(
                        listing: listing,
                        onTap: {
                            navigationPath.append(.listing(id: listing.id))
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
        if store.filteredListings.isEmpty && !store.isLoading {
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

    private var teamToggle: some View {
        TeamToggle(selection: $store.teamFilter)
            .padding(.leading, 16)
            .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview {
    AllListingsView(repository: .preview)
}
