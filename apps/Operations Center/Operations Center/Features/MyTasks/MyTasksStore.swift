//
//  MyTasksStore.swift
//  Operations Center
//
//  Store for My Tasks screen
//  Per TASK_MANAGEMENT_SPEC.md lines 172-194
//

import Dependencies
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

    var tasks: [AgentTask] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    /// Initialize store with repository injection
    /// Following Context7 @Observable pattern
    init(repository: TaskRepositoryClient, initialTasks: [AgentTask] = []) {
        self.repository = repository
        self.tasks = initialTasks
    }

    // MARK: - Actions

    /// Fetch tasks claimed by current user
    /// Per spec line 173, 176: "See all Tasks I've claimed"
    /// Loads tasks assigned to the current user and updates the store state.
    /// 
    /// Filters fetched agent tasks to those whose `assignedStaffId` matches the current user ID and whose status is `.claimed` or `.inProgress`. Sets `isLoading` to true for the duration of the operation. On success updates `tasks` and clears `errorMessage`; on failure sets `errorMessage` to `Failed to load tasks: <underlying description>`.
    func fetchMyTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch agent tasks and filter for current user
            let tasksResults = try await repository.fetchTasks()

            // Filter for agent tasks claimed by me - break up for type-checker
            let allAgentTasks = tasksResults.map(\.task)
            tasks = allAgentTasks.filter { task in
                task.assignedStaffId == authClient.currentUserId() &&
                (task.status == .claimed || task.status == .inProgress)
            }

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
    /// Claims the provided task on behalf of the current user and refreshes the store's task list.
    /// - Parameter task: The task to claim; its `id` will be used for the claim operation.
    /// - Note: If the claim fails, `errorMessage` is set with a descriptive message.
    func claimTask(_ task: AgentTask) async {
        do {
            _ = try await repository.claimTask(task.id, authClient.currentUserId())
            await fetchMyTasks()
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Deletes the provided task and refreshes the current user's task list.
    /// 
    /// Attempts to remove `task` from the repository for the current authenticated user. On success, the store reloads the user's tasks; on failure, `errorMessage` is set with a descriptive failure message.
    /// - Parameter task: The `AgentTask` to delete; deletion is performed on behalf of the current authenticated user.
    func deleteTask(_ task: AgentTask) async {
        do {
            try await repository.deleteTask(task.id, authClient.currentUserId())
            await fetchMyTasks()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Toggle task user type (Marketing/Admin)
    /// Per spec line 79: "Tagged as Marketing or Admin (can be toggled)"
    func toggleUserType(for task: AgentTask) async {
        // NOTE: Implement task category update when repository supports it
        errorMessage = "Category toggle not yet implemented"
    }
}