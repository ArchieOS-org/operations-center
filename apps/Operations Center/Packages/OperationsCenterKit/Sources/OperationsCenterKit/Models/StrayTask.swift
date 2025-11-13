//
//  StrayTask.swift
//  OperationsCenterKit
//
//  Data model for stray_tasks table (general agent tasks not tied to a listing)
//

import Foundation

public struct StrayTask: Identifiable, Codable, Sendable {
    public let id: String
    public let realtorId: String
    public let name: String
    public let description: String?
    public let taskCategory: TaskCategory
    public let status: TaskStatus
    public let priority: Int
    public let assignedStaffId: String?
    public let dueDate: Date?
    public let claimedAt: Date?
    public let completedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let deletedBy: String?

    // MARK: - Nested Types

    public enum TaskCategory: String, Codable, Sendable {
        case admin = "ADMIN"
        case marketing = "MARKETING"
        case photo = "PHOTO"
        case staging = "STAGING"
        case inspection = "INSPECTION"
        case other = "OTHER"
    }

    public enum TaskStatus: String, Codable, Sendable {
        case open = "OPEN"
        case claimed = "CLAIMED"
        case inProgress = "IN_PROGRESS"
        case done = "DONE"
        case failed = "FAILED"
        case cancelled = "CANCELLED"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case realtorId = "realtor_id"
        case name
        case description
        case taskCategory = "task_category"
        case status
        case priority
        case assignedStaffId = "assigned_staff_id"
        case dueDate = "due_date"
        case claimedAt = "claimed_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case deletedBy = "deleted_by"
    }

    // MARK: - Computed Properties

    public var isCompleted: Bool {
        status == .done
    }

    public var isOverdue: Bool {
        guard let dueDate, status != .done else { return false }
        return dueDate < Date()
    }
}
