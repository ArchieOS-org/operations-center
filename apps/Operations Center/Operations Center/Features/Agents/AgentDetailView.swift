//
//  AgentDetailView.swift
//  Operations Center
//
//  Agent Detail screen - shows all work for a specific agent
//  Per TASK_MANAGEMENT_SPEC.md lines 272-283
//

import SwiftUI
import OperationsCenterKit
import Supabase

/// Agent Detail screen - displays all listings and tasks for a specific agent
/// Shows both claimed and unclaimed work
struct AgentDetailView: View {
    // MARK: - Properties

    /// Store is @Observable AND @State for projected value binding
    /// @State wrapper enables $store for Binding properties
    @State private var store: AgentDetailStore

    // MARK: - Initialization

    init(
        realtorId: String,
        realtorRepository: RealtorRepositoryClient,
        taskRepository: TaskRepositoryClient,
        supabase: SupabaseClient
    ) {
        _store = State(initialValue: AgentDetailStore(
            realtorId: realtorId,
            realtorRepository: realtorRepository,
            taskRepository: taskRepository,
            supabase: supabase
        ))
    }

    // MARK: - Body

    var body: some View {
        List {
            agentInfoSection
            listingsSection
            activitiesSection
            tasksSection
            emptyStateSection
        }
        .listStyle(.plain)
        .navigationTitle(store.realtor?.name ?? "Agent")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchAgentData()
        }
        .loadingOverlay(store.isLoading)
        .overlay(alignment: .bottom) {
            // Floating context menu - appears at screen bottom when card is expanded
            if let expandedId = store.expandedTaskId {
                Group {
                    if let task = findExpandedTask(id: expandedId) {
                        DSContextMenu(actions: buildTaskActions(for: task))
                    } else if let activity = findExpandedActivity(id: expandedId) {
                        DSContextMenu(actions: buildActivityActions(for: activity))
                    }
                }
                .padding(.bottom, Spacing.lg)
                .padding(.horizontal, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedTaskId)
        .errorAlert($store.errorMessage)
    }

    // MARK: - Helpers

    private func findExpandedTask(id: String) -> AgentTask? {
        store.tasks.first(where: { $0.task.id == id })?.task
    }

    private func findExpandedActivity(id: String) -> Activity? {
        store.activities.first(where: { $0.task.id == id })?.task
    }

    private func buildTaskActions(for task: AgentTask) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
            onClaim: {
                Task { await store.claimTask(task) }
            },
            onDelete: {
                Task { await store.deleteTask(task) }
            }
        )
    }

    private func buildActivityActions(for activity: Activity) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
            onClaim: {
                Task { await store.claimActivity(activity) }
            },
            onDelete: {
                Task { await store.deleteActivity(activity) }
            }
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private var agentInfoSection: some View {
        if let realtor = store.realtor {
            Section {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(realtor.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            if let brokerage = realtor.brokerage {
                                Text(brokerage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if realtor.status != .active {
                            Text(realtor.status.displayName)
                                .font(.caption)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    if !realtor.territories.isEmpty {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "map")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(realtor.territories.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "envelope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(realtor.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
    }

    @ViewBuilder
    private var listingsSection: some View {
        if !store.listings.isEmpty {
            Section("Listings") {
                ForEach(store.listings, id: \.listing.id) { listingWithActivities in
                    NavigationLink(value: Route.listing(id: listingWithActivities.listing.id)) {
                        ListingBrowseCard(listing: listingWithActivities.listing)
                    }
                    .listRowSeparator(.hidden)
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var activitiesSection: some View {
        if !store.activities.isEmpty {
            Section("Property Tasks") {
                ForEach(store.activities, id: \.task.id) { taskWithDetails in
                    ActivityCard(
                        task: taskWithDetails.task,
                        listing: taskWithDetails.listing,
                        isExpanded: store.expandedTaskId == taskWithDetails.task.id,
                        onTap: {
                            store.toggleTaskExpansion(for: taskWithDetails.task.id)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var tasksSection: some View {
        if !store.tasks.isEmpty {
            Section("General Tasks") {
                ForEach(store.tasks, id: \.task.id) { taskWithMessages in
                    TaskCard(
                        task: taskWithMessages.task,
                        messages: taskWithMessages.messages,
                        isExpanded: store.expandedTaskId == taskWithMessages.task.id,
                        onTap: {
                            store.toggleTaskExpansion(for: taskWithMessages.task.id)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .standardListRowInsets()
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.listings.isEmpty && store.activities.isEmpty && store.tasks.isEmpty && !store.isLoading {
            DSEmptyState(
                icon: "tray",
                title: "No work for this agent",
                message: "Work items will appear here when they're assigned"
            )
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentDetailView(
            realtorId: "realtor_001",
            realtorRepository: .preview,
            taskRepository: .preview,
            supabase: supabase
        )
    }
}
