//
//  AdminTeamStore.swift
//  Operations Center
//
//  Admin team view store - shows all admin tasks/activities
//

import Foundation
import OperationsCenterKit
import Dependencies

@Observable @MainActor
final class AdminTeamStore: TeamViewStoreBase, TeamViewStore {
    // MARK: - Computed Properties

    /// All admin tasks (standalone + property-linked activities)
    var allAdminItems: Int {
        tasks.count + activities.count
    }

    // MARK: - Data Loading

    override func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all tasks and activities, filter to admin category only
            async let tasksResult = taskRepository.fetchTasks()
            async let activitiesResult = taskRepository.fetchActivities()

            let (allTasks, allActivities) = try await (tasksResult, activitiesResult)

            // Filter to admin category only
            tasks = allTasks.filter { $0.task.taskCategory == .admin }
            activities = allActivities.filter { $0.task.taskCategory == .admin }

        } catch {
            errorMessage = "Failed to load admin tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
