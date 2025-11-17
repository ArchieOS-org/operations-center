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
                .standardListRowInsets()
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
        .loadingOverlay(store.isLoading)
        .errorAlert($store.errorMessage)
    }
}

// MARK: - Realtor Row

private struct RealtorRow: View {
    let realtor: Realtor

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(realtor.name)
                    .font(.headline)

                Spacer()

                if realtor.status != .active {
                    Text(realtor.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
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
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(realtor.territories.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentsView(repository: .preview)
    }
}
