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
    /// Fetch all stray tasks with their associated Slack messages
    func fetchStrayTasks() async throws -> [StrayTaskWithMessages]

    /// Fetch all listing tasks with their listing data and subtasks
    func fetchListingTasks() async throws -> [ListingTaskWithDetails]

    /// Claim a stray task
    func claimStrayTask(taskId: String, staffId: String) async throws -> StrayTask

    /// Claim a listing task
    func claimListingTask(taskId: String, staffId: String) async throws -> ListingTask

    /// Delete a stray task (soft delete)
    func deleteStrayTask(taskId: String, deletedBy: String) async throws

    /// Delete a listing task (soft delete)
    func deleteListingTask(taskId: String, deletedBy: String) async throws

    /// Complete a subtask within a listing task
    func completeSubtask(subtaskId: String) async throws -> Subtask

    /// Uncomplete a subtask within a listing task
    func uncompleteSubtask(subtaskId: String) async throws -> Subtask
}
