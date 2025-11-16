//
//  Subtask.swift
//  OperationsCenterKit
//
//  Represents a subtask within a activity
//

import Foundation

public struct Subtask: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let parentTaskId: String
    public let name: String
    public let isCompleted: Bool
    public var completedAt: Date?
    public let createdAt: Date

    public init(
        id: String,
        parentTaskId: String,
        name: String,
        isCompleted: Bool,
        completedAt: Date? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.parentTaskId = parentTaskId
        self.name = name
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "subtask_id"
        case parentTaskId = "parent_task_id"
        case name
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}

// MARK: - Mock Data

extension Subtask {
    /// Mock data for testing and previews
    /// Note: Using computed properties (var) instead of static constants (let) to ensure dates are always relative to "now"

    public static var mock1: Subtask {
        Subtask(
            id: "subtask_001",
            parentTaskId: "task_001",
            name: "Schedule photographer",
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-86400), // 1 day ago
            createdAt: Date().addingTimeInterval(-86400 * 3) // 3 days ago
        )
    }

    public static var mock2: Subtask {
        Subtask(
            id: "subtask_002",
            parentTaskId: "task_001",
            name: "Prepare property for photos",
            isCompleted: false,
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 3) // 3 days ago
        )
    }

    public static var mock3: Subtask {
        Subtask(
            id: "subtask_003",
            parentTaskId: "task_003",
            name: "Review inspection report",
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            createdAt: Date().addingTimeInterval(-86400 * 7) // 7 days ago
        )
    }
}
