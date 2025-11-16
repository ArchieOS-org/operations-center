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
                Text("No listings with claimed activities")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Listings will appear here when you claim activities")
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
    MyListingsView(
        listingRepository: .preview,
        taskRepository: .preview
    )
}
