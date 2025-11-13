//
//  TaskListStore.swift
//  Operations Center
//
//  Created by Claude Code
//

import Foundation
import Dependencies
import Supabase
import OperationsCenterKit

/// Store managing the list of tasks with Supabase integration
@Observable
@MainActor
final class TaskListStore {
    // MARK: - Observable State

    var tasks: [ListingTask] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.supabaseClient) var supabaseClient

    // MARK: - Initializer

    init() {}

    // MARK: - Actions

    /// Fetch all listing tasks from Supabase
    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: [ListingTask] = try await supabaseClient
                .from("listing_tasks")
                .select()
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            tasks = response
            print("✅ Successfully fetched \(tasks.count) tasks")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ Error fetching tasks: \(error)")
        }

        isLoading = false
    }

    /// Claim a task by assigning it to a staff member
    func claimTask(_ task: ListingTask, staffId: String) async {
        do {
            try await supabaseClient
                .from("listing_tasks")
                .update(["assigned_staff_id": staffId])
                .eq("id", value: task.id)
                .execute()

            print("✅ Task claimed: \(task.name)")

            // Refresh to get updated data
            await fetchTasks()
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
            print("❌ Error claiming task: \(error)")
        }
    }

    /// Mark a task as complete
    func completeTask(_ task: ListingTask) async {
        do {
            try await supabaseClient
                .from("listing_tasks")
                .update(["status": ListingTask.TaskStatus.done.rawValue])
                .eq("id", value: task.id)
                .execute()

            print("✅ Task completed: \(task.name)")

            // Refresh to get updated data
            await fetchTasks()
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
            print("❌ Error completing task: \(error)")
        }
    }

    /// Refresh tasks (for pull-to-refresh)
    func refresh() async {
        await fetchTasks()
    }
}
