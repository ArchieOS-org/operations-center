//
//  TaskRepository.swift
//  OperationsCenterKit
//
//  Protocol defining task repository interface for dependency injection
//  Implementations: MockTaskRepository (testing), SupabaseTaskRepository (production)
//

import Foundation

/// Repository protocol for task operations
/// Enables seamless swap from mock to production data sources
public protocol TaskRepository: Sendable {
    /// Fetch all tasks with their associated Slack messages
    func fetchTasks() async throws -> [TaskWithMessages]

    /// Fetch all activities with their listing data and subtasks
    func fetchActivities() async throws -> [ActivityWithDetails]

    /// Claim a task
    func claimTask(taskId: String, staffId: String) async throws -> AgentTask

    /// Claim an activity
    func claimActivity(taskId: String, staffId: String) async throws -> Activity

    /// Delete a task (soft delete)
    func deleteTask(taskId: String, deletedBy: String) async throws

    /// Delete an activity (soft delete)
    func deleteActivity(taskId: String, deletedBy: String) async throws

    /// Complete a subtask within an activity
    func completeSubtask(subtaskId: String) async throws -> Subtask

    /// Uncomplete a subtask within an activity
    func uncompleteSubtask(subtaskId: String) async throws -> Subtask
}
