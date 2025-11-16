//
//  AgentDetailView.swift
//  Operations Center
//
//  Agent Detail screen - shows all work for a specific agent
//  Per TASK_MANAGEMENT_SPEC.md lines 272-283
//

import SwiftUI
import OperationsCenterKit

/// Agent Detail screen - displays all listings and tasks for a specific agent
/// Shows both claimed and unclaimed work
struct AgentDetailView: View {
    // MARK: - Properties

    @State private var store: AgentDetailStore

    // MARK: - Initialization

    init(
        realtorId: String,
        realtorRepository: RealtorRepositoryClient,
        taskRepository: TaskRepositoryClient
    ) {
        _store = State(initialValue: AgentDetailStore(
            realtorId: realtorId,
            realtorRepository: realtorRepository,
            taskRepository: taskRepository
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
    private var agentInfoSection: some View {
        if let realtor = store.realtor {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    if !realtor.territories.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "map")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(realtor.territories.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(realtor.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var listingsSection: some View {
        if !store.listings.isEmpty {
            Section("Listings") {
                ForEach(store.listings, id: \.listing.id) { listingWithActivities in
                    ListingBrowseCard(
                        listing: listingWithActivities.listing,
                        onTap: {
                            // TODO: Navigate to listing detail
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
                        subtasks: taskWithDetails.subtasks,
                        isExpanded: store.expandedTaskId == taskWithDetails.task.id,
                        onTap: {
                            store.toggleTaskExpansion(for: taskWithDetails.task.id)
                        },
                        onSubtaskToggle: { _ in
                            // TODO: Implement subtask toggle
                        },
                        onClaim: {
                            Task {
                                await store.claimActivity(taskWithDetails.task)
                            }
                        },
                        onDelete: {
                            Task {
                                await store.deleteActivity(taskWithDetails.task)
                            }
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
                        },
                        onClaim: {
                            Task {
                                await store.claimTask(taskWithMessages.task)
                            }
                        },
                        onDelete: {
                            Task {
                                await store.deleteTask(taskWithMessages.task)
                            }
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
        if store.listings.isEmpty && store.activities.isEmpty && store.tasks.isEmpty && !store.isLoading {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("No work for this agent")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
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
            taskRepository: .preview
        )
    }
}
