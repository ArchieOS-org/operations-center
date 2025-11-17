//
//  AgentsView.swift
//  Operations Center
//
//  Agents list screen - shows all active agents/realtors
//  Per TASK_MANAGEMENT_SPEC.md lines 260-270
//

import SwiftUI
import OperationsCenterKit

/// Agents screen - list of all agents to browse work by agent
/// Per spec: "Purpose: Browse work by agent"
/// Shows: List of all agents
/// Interaction: Click Agent → Navigate to Agent Screen
struct AgentsView: View {
    // MARK: - Properties

    @State private var store: AgentsStore

    // MARK: - Initialization

    init(repository: RealtorRepositoryClient) {
        _store = State(initialValue: AgentsStore(repository: repository))
    }

    // MARK: - Body

    var body: some View {
        OCListScaffold(
            onRefresh: {
                await store.refresh()
            }
        ) {
            agentsSection
            emptyStateSection
        }
        .navigationTitle("Agents")
        .task {
            await store.fetchRealtors()
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
    private var agentsSection: some View {
        if !store.realtors.isEmpty {
            Section {
                ForEach(store.realtors) { realtor in
                    NavigationLink(value: Route.agent(id: realtor.id)) {
                        OCAgentRow(realtor: realtor)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if store.realtors.isEmpty && !store.isLoading {
            OCEmptyState.noAgents
                .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentsView(repository: .preview)
    }
}
