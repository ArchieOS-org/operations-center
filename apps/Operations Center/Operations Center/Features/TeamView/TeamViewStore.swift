//
//  TeamViewStore.swift
//  Operations Center
//
//  Protocol for team view stores
//  Eliminates duplication between MarketingTeamStore and AdminTeamStore
//

import Foundation
import OperationsCenterKit
import Dependencies

/// Protocol for team view stores
/// Both MarketingTeamStore and AdminTeamStore conform to this
@MainActor
protocol TeamViewStore: Observable {
    var tasks: [TaskWithMessages] { get }
    var activities: [ActivityWithDetails] { get }
    var expandedTaskId: String? { get set }
    var isLoading: Bool { get }
    var errorMessage: String? { get set }

    // Dependencies that conformers must provide
    var taskRepository: TaskRepositoryClient { get }
    var authClient: AuthClient { get }

    func loadTasks() async
    func toggleExpansion(for taskId: String)
    func claimTask(_ task: AgentTask) async
    func claimActivity(_ activity: Activity) async
    func deleteTask(_ task: AgentTask) async
    func deleteActivity(_ activity: Activity) async
}

// MARK: - Shared Helper

/// Shared base class for team view stores to eliminate duplication
/// Contains all common mutation logic
@Observable @MainActor
class TeamViewStoreBase {
    // MARK: - Observable State

    var tasks: [TaskWithMessages] = []
    var activities: [ActivityWithDetails] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    let taskRepository: TaskRepositoryClient
    @ObservationIgnored @Dependency(\.authClient) var authClient

    // MARK: - Initialization

    init(taskRepository: TaskRepositoryClient) {
        self.taskRepository = taskRepository
    }

    // MARK: - Actions

    func toggleExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
        }
    }

    func claimTask(_ task: AgentTask) async {
        do {
            let userId = try await authClient.currentUserId()
            _ = try await taskRepository.claimTask(task.id, userId)
            await loadTasks()
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    func claimActivity(_ activity: Activity) async {
        do {
            let userId = try await authClient.currentUserId()
            _ = try await taskRepository.claimActivity(activity.id, userId)
            await loadTasks()
        } catch {
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    func deleteTask(_ task: AgentTask) async {
        do {
            let userId = try await authClient.currentUserId()
            try await taskRepository.deleteTask(task.id, userId)
            await loadTasks()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    func deleteActivity(_ activity: Activity) async {
        do {
            let userId = try await authClient.currentUserId()
            try await taskRepository.deleteActivity(activity.id, userId)
            await loadTasks()
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Abstract Method

    /// Subclasses must override this to filter tasks by their category
    func loadTasks() async {
        fatalError("Subclasses must override loadTasks()")
    }
}
