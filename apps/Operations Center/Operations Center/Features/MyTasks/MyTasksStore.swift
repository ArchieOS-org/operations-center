//
//  MyTasksStore.swift
//  Operations Center
//
//  Store for My Tasks screen
//  Per TASK_MANAGEMENT_SPEC.md lines 172-194
//

import Foundation
import Observation
import OperationsCenterKit

/// Store for My Tasks screen
///
/// Per TASK_MANAGEMENT_SPEC.md:
/// - "See all Tasks I've claimed" (line 173)
/// - "Standalone Tasks claimed by user (no Activities)" (line 176)
/// - "Tasks I've claimed that are also assigned to Listings" (line 177)
@Observable @MainActor
final class MyTasksStore {
    // MARK: - Dependencies

    private let repository: TaskRepositoryClient

    // MARK: - State

    var tasks: [StrayTask] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Initialization

    /// Initialize store with repository injection
    /// Following Context7 @Observable pattern
    init(repository: TaskRepositoryClient, initialTasks: [StrayTask] = []) {
        self.repository = repository
        self.tasks = initialTasks
    }

    // MARK: - Actions

    /// Fetch tasks claimed by current user
    /// Per spec line 173: "See all Tasks I've claimed"
    func fetchMyTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch all stray tasks and filter for now
            // TODO: Add proper user filtering when auth is implemented
            let allTasks = try await repository.fetchStrayTasks()
            tasks = allTasks.map(\.task)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
    }

    /// Toggle expansion for a task
    func toggleExpansion(for taskId: String) {
        expandedTaskId = expandedTaskId == taskId ? nil : taskId
    }

    /// Claim a task for current user
    /// Per spec line 428: "Press: Claim for yourself"
    func claimTask(_ task: StrayTask) async {
        do {
            // TODO: Use actual user ID when auth is implemented
            _ = try await repository.claimStrayTask(task.id, "current-user")
            await fetchMyTasks()
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Delete a task
    func deleteTask(_ task: StrayTask) async {
        do {
            // TODO: Use actual user ID when auth is implemented
            try await repository.deleteStrayTask(task.id, "current-user")
            await fetchMyTasks()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Toggle task user type (Marketing/Admin)
    /// Per spec line 79: "Tagged as Marketing or Admin (can be toggled)"
    func toggleUserType(for task: StrayTask) async {
        // TODO: Implement task category update when repository supports it
        errorMessage = "Category toggle not yet implemented"
    }
}
