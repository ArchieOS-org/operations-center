//
//  AllTasksStore.swift
//  Operations Center
//
//  All Tasks screen store - shows all claimed tasks system-wide
//  Per TASK_MANAGEMENT_SPEC.md lines 286-305
//

import Dependencies
import Foundation
import OperationsCenterKit
import OSLog
import SwiftUI

/// Store for All Tasks screen - all claimed tasks across the entire system
/// Per spec: "All claimed Tasks system-wide (standalone + assigned to listings)"
@MainActor
@Observable
final class AllTasksStore {
    // MARK: - Properties

    /// All agent tasks (standalone tasks)
    private(set) var tasks: [TaskWithMessages] = [] {
        didSet {
            updateFilteredTasks()
        }
    }

    /// All activities (property-linked tasks)
    private(set) var activities: [ActivityWithDetails] = []

    /// Currently expanded task ID (only one can be expanded at a time)
    var expandedTaskId: String?

    /// Filter by team: marketing, admin, or all
    var teamFilter: OperationsCenterKit.TeamFilter = .all {
        didSet {
            updateFilteredTasks()
        }
    }

    /// Cached filtered tasks - updated when tasks or filter changes
    /// Performance: Filter runs once per change, not 60x/second
    private(set) var filteredTasks: [TaskWithMessages] = []

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repository for data access
    private let repository: TaskRepositoryClient

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    init(repository: TaskRepositoryClient) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Fetch all claimed tasks
    func fetchAllTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            async let tasksFetch = repository.fetchTasks()
            async let activitiesFetch = repository.fetchActivities()

            let (stray, listing) = try await (tasksFetch, activitiesFetch)

            // Filter only claimed tasks
            tasks = stray.filter { $0.task.status == .claimed || $0.task.status == .inProgress }
            activities = listing.filter { $0.task.status == .claimed || $0.task.status == .inProgress }
        } catch {
            Logger.tasks.error("Failed to fetch all tasks: \(error.localizedDescription)")
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await fetchAllTasks()
    }

    /// Toggle expansion for a task
    func toggleExpansion(for taskId: String) {
        expandedTaskId = expandedTaskId == taskId ? nil : taskId
    }

    /// Claim a agent task
    func claimTask(_ task: AgentTask) async {
        do {
            let userId = try await authClient.currentUserId()
            _ = try await repository.claimTask(task.id, userId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to claim agent task: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Claim a activity
    func claimActivity(_ task: Activity) async {
        do {
            let userId = try await authClient.currentUserId()
            _ = try await repository.claimActivity(task.id, userId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to claim activity: \(error.localizedDescription)")
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
        }
    }

    /// Delete a agent task
    func deleteTask(_ task: AgentTask) async {
        do {
            let userId = try await authClient.currentUserId()
            try await repository.deleteTask(task.id, userId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to delete agent task: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    /// Delete a activity
    func deleteActivity(_ task: Activity) async {
        do {
            let userId = try await authClient.currentUserId()
            try await repository.deleteActivity(task.id, userId)

            await refresh()
        } catch {
            Logger.tasks.error("Failed to delete activity: \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Update cached filtered tasks when data or filter changes
    /// Performance optimization: Filter runs once per change, not on every SwiftUI redraw
    private func updateFilteredTasks() {
        switch teamFilter {
        case .all:
            filteredTasks = tasks
        case .marketing:
            filteredTasks = tasks.filter { $0.task.taskCategory == .marketing }
        case .admin:
            filteredTasks = tasks.filter { $0.task.taskCategory == .admin }
        }
    }

    // MARK: - Computed Properties

    /// Filtered activities based on team filter
    var filteredActivities: [ActivityWithDetails] {
        switch teamFilter {
        case .all:
            return activities
        case .marketing:
            return activities.filter { $0.task.visibilityGroup == .marketing || $0.task.visibilityGroup == .both }
        case .admin:
            return activities.filter { $0.task.visibilityGroup == .agent || $0.task.visibilityGroup == .both }
        }
    }
}
