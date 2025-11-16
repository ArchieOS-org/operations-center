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
    public var status: TaskStatus
    public let priority: Int
    public var assignedStaffId: String?
    public let dueDate: Date?
    public var claimedAt: Date?
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

    // MARK: - Initialization

    /// Memberwise initializer required for Codable types
    /// Codable synthesis only provides init(from: Decoder), not memberwise init
    public init(
        id: String,
        realtorId: String,
        name: String,
        description: String? = nil,
        taskCategory: TaskCategory,
        status: TaskStatus,
        priority: Int,
        assignedStaffId: String? = nil,
        dueDate: Date? = nil,
        claimedAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        deletedBy: String? = nil
    ) {
        self.id = id
        self.realtorId = realtorId
        self.name = name
        self.description = description
        self.taskCategory = taskCategory
        self.status = status
        self.priority = priority
        self.assignedStaffId = assignedStaffId
        self.dueDate = dueDate
        self.claimedAt = claimedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.deletedBy = deletedBy
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

// MARK: - Mock Data

extension StrayTask {
    /// Mock data for testing and previews
    /// Context7 best practice: Keep mock data with the model
    /// Reference: swift-dependencies/Articles/LivePreviewTest.md
    /// Note: Using computed properties (var) instead of static constants (let) to ensure dates are always relative to "now"

    public static var mock1: StrayTask {
        StrayTask(
            id: "stray_001",
            realtorId: "realtor_001",
            name: "Update CRM Records",
            description: "Update all client contact information in the CRM system",
            taskCategory: .admin,
            status: .open,
            priority: 75,
            assignedStaffId: nil,
            dueDate: Date().addingTimeInterval(86400 * 1), // 1 day from now
            claimedAt: nil,
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            deletedAt: nil,
            deletedBy: nil
        )
    }

    public static var mock2: StrayTask {
        StrayTask(
            id: "stray_002",
            realtorId: "realtor_002",
            name: "Email Marketing Campaign",
            description: "Design and send monthly newsletter to all subscribers",
            taskCategory: .marketing,
            status: .claimed,
            priority: 60,
            assignedStaffId: "staff_003",
            dueDate: Date().addingTimeInterval(86400 * 5), // 5 days from now
            claimedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            updatedAt: Date().addingTimeInterval(-3600),
            deletedAt: nil,
            deletedBy: nil
        )
    }

    public static var mock3: StrayTask {
        StrayTask(
            id: "stray_003",
            realtorId: "realtor_001",
            name: "Portfolio Photos Update",
            description: "Update website portfolio with recent property photos",
            taskCategory: .photo,
            status: .inProgress,
            priority: 50,
            assignedStaffId: "staff_001",
            dueDate: Date().addingTimeInterval(86400 * 2), // 2 days from now
            claimedAt: Date().addingTimeInterval(-86400 * 1), // 1 day ago
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 4), // 4 days ago
            updatedAt: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
            deletedAt: nil,
            deletedBy: nil
        )
    }
}
