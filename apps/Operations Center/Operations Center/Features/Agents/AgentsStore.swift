//
//  AgentsStore.swift
//  Operations Center
//
//  Store managing the list of agents/realtors
//  Per TASK_MANAGEMENT_SPEC.md lines 260-270
//

import Foundation
import OperationsCenterKit
import OSLog

/// Store managing the list of agents/realtors
@Observable
@MainActor
final class AgentsStore {
    // MARK: - Observable State

    private(set) var realtors: [Realtor] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let repository: RealtorRepositoryClient

    // MARK: - Initialization

    /// For production: AgentsStore(repository: .live)
    /// For previews: AgentsStore(repository: .preview)
    init(repository: RealtorRepositoryClient) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Fetch all active realtors
    func fetchRealtors() async {
        isLoading = true
        errorMessage = nil

        do {
            realtors = try await repository.fetchRealtors()
            Logger.database.info("Fetched \(self.realtors.count) realtors")
        } catch {
            Logger.database.error("Failed to fetch realtors: \(error.localizedDescription)")
            errorMessage = "Failed to load agents: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh the list
    func refresh() async {
        await fetchRealtors()
    }
}
