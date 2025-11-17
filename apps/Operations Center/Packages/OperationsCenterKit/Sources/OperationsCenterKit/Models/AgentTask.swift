//
//  AgentTask.swift
//  OperationsCenterKit
//
//  Data model for tasks table (general agent tasks not tied to a listing)
//

import Foundation

public struct AgentTask: Identifiable, Codable, Sendable {
    public let id: String
    public let realtorId: String
    public let name: String
    public let description: String?
    public let taskCategory: TaskCategory?  // Optional: admin, marketing, or nil
    public var listingId: String?  // NEW: Optional assignment to a listing
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
    // TaskCategory is now imported from shared TaskCategory.swift

    public enum TaskStatus: String, Codable, Sendable {
        case open = "OPEN"
        case claimed = "CLAIMED"
        case inProgress = "IN_PROGRESS"
        case done = "DONE"
        case failed = "FAILED"
        case cancelled = "CANCELLED"

        public var displayName: String {
            switch self {
            case .open: return "Open"
            case .claimed: return "Claimed"
            case .inProgress: return "In Progress"
            case .done: return "Done"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
    }

    // MARK: - Initialization

    /// Memberwise initializer required for Codable types
    /// Codable synthesis only provides init(from: Decoder), not memberwise init
    public init(
        id: String,
        realtorId: String,
        name: String,
        description: String? = nil,
        taskCategory: TaskCategory? = nil,  // Optional category
        listingId: String? = nil,  // NEW: Optional listing assignment
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
        self.listingId = listingId
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
        case listingId = "listing_id"  // NEW
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

extension AgentTask {
    /// Mock data for testing and previews
    /// Context7 best practice: Keep mock data with the model
    /// Reference: swift-dependencies/Articles/LivePreviewTest.md
    /// Note: Using computed properties (var) instead of static constants (let) to ensure dates are always relative to "now"

    public static var mock1: AgentTask {
        AgentTask(
            id: "task_001",
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

    public static var mock2: AgentTask {
        AgentTask(
            id: "task_002",
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

    public static var mock3: AgentTask {
        AgentTask(
            id: "task_003",
            realtorId: "realtor_001",
            name: "Portfolio Photos Update",
            description: "Update website portfolio with recent property photos",
            taskCategory: nil,  // Uncategorized
            listingId: nil,  // Not assigned to a listing
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
