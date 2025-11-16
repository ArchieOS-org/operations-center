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
        List {
            ForEach(store.realtors) { realtor in
                NavigationLink(value: Route.agent(id: realtor.id)) {
                    RealtorRow(realtor: realtor)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Agents")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchRealtors()
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
}

// MARK: - Realtor Row

private struct RealtorRow: View {
    let realtor: Realtor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(realtor.name)
                    .font(.headline)

                Spacer()

                if realtor.status != .active {
                    Text(realtor.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if let brokerage = realtor.brokerage {
                Text(brokerage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !realtor.territories.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(realtor.territories.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentsView(repository: .preview)
    }
}
