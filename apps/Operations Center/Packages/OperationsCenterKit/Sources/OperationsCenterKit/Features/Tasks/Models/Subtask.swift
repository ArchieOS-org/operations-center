//
//  Subtask.swift
//  OperationsCenterKit
//
//  Represents a subtask within a listing task
//

import Foundation

public struct Subtask: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let parentTaskId: String
    public let name: String
    public let isCompleted: Bool
    public let completedAt: Date?
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
