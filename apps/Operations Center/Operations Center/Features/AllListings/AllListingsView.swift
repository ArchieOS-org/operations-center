//
//  AllListingsView.swift
//  Operations Center
//
//  All Listings screen - shows all listings system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 307-322
//

import SwiftUI
import OperationsCenterKit
import Supabase

/// All Listings screen - browse all listings to claim Activities
/// Per spec: "All Listings across system (acknowledged and unacknowledged)"
/// Features: Collapsed cards only, click-to-navigate
struct AllListingsView: View {
    // MARK: - Properties

    /// Store is @Observable AND @State for projected value binding
    /// @State wrapper enables $store for Binding properties
    @State private var store: AllListingsStore

    // MARK: - Initialization

    init(
        listingRepository: ListingRepositoryClient,
        taskRepository: TaskRepositoryClient,
        supabase: SupabaseClient,
        listingCoalescer: ListingFetchCoalescer,
        activityCoalescer: ActivityFetchCoalescer
    ) {
        _store = State(initialValue: AllListingsStore(
            listingRepository: listingRepository,
            taskRepository: taskRepository,
            supabase: supabase,
            listingCoalescer: listingCoalescer,
            activityCoalescer: activityCoalescer
        ))
    }

    // MARK: - Body

    var body: some View {
        listingsList
    }

    // MARK: - Subviews

    private var listingsList: some View {
        List {
            categoryFilterSection
            if store.isLoading {
                skeletonSection
            } else {
                listingsSection
                emptyStateSection
            }
        }
        .listStyle(.plain)
        .navigationTitle("All Listings")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchAllListings()
        }
        .errorAlert($store.errorMessage)
    }

    private var categoryFilterSection: some View {
        CategoryFilterPicker(selection: $store.selectedCategory)
    }

    @ViewBuilder
    private var listingsSection: some View {
        if !store.filteredListings.isEmpty {
            Section {
                ForEach(store.filteredListings, id: \.id) { listing in
                    NavigationLink(value: Route.listing(id: listing.id)) {
                        ListingCollapsedContent(listing: listing)
                    }
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var skeletonSection: some View {
        Section {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonCard(tintColor: Colors.surfaceListingTinted)
                    .skeletonShimmer()
                    .listRowSeparator(.hidden)
                    .standardListRowInsets()
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.filteredListings.isEmpty && !store.isLoading {
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
    AllListingsView(
        listingRepository: .preview,
        taskRepository: .preview,
        supabase: supabase,
        listingCoalescer: ListingFetchCoalescer(),
        activityCoalescer: ActivityFetchCoalescer()
    )
}
