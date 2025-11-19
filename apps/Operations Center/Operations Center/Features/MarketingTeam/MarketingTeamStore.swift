//
//  MarketingTeamStore.swift
//  Operations Center
//
//  Marketing team view store - shows all marketing tasks/activities
//

import Foundation
import OperationsCenterKit
import Dependencies

@Observable @MainActor
final class MarketingTeamStore: TeamViewStoreBase, TeamViewStore {
    // MARK: - Computed Properties

    /// All marketing tasks (standalone + property-linked activities)
    var allMarketingItems: Int {
        tasks.count + activities.count
    }

    // MARK: - Data Loading

    override func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all tasks and activities, filter to marketing category only
            async let tasksResult = taskRepository.fetchTasks()
            async let activitiesResult = taskRepository.fetchActivities()

            let (allTasks, allActivities) = try await (tasksResult, activitiesResult)

            // Filter to marketing category only
            tasks = allTasks.filter { $0.task.taskCategory == .marketing }
            activities = allActivities.filter { $0.task.taskCategory == .marketing }

        } catch {
            errorMessage = "Failed to load marketing tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
