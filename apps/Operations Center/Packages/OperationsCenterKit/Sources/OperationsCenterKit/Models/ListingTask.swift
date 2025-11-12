//
//  ListingTask.swift
//  Operations Center
//
//  Data model for listing_tasks table
//

import Foundation

public struct ListingTask: Identifiable, Codable, Sendable {
    public let id: String
    public let listingId: String
    public let realtorId: String?
    public let name: String
    public let description: String?
    public let taskCategory: TaskCategory
    public let status: TaskStatus
    public let priority: Int
    public let visibilityGroup: VisibilityGroup
    public let assignedStaffId: String?
    public let dueDate: Date?
    public let claimedAt: Date?
    public let completedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let deletedBy: String?
    public let inputs: [String: AnyCodable]?
    public let outputs: [String: AnyCodable]?

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

    public enum VisibilityGroup: String, Codable, Sendable {
        case both = "BOTH"
        case agent = "AGENT"
        case marketing = "MARKETING"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case listingId = "listing_id"
        case realtorId = "realtor_id"
        case name
        case description
        case taskCategory = "task_category"
        case status
        case priority
        case visibilityGroup = "visibility_group"
        case assignedStaffId = "assigned_staff_id"
        case dueDate = "due_date"
        case claimedAt = "claimed_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case deletedBy = "deleted_by"
        case inputs
        case outputs
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

// MARK: - AnyCodable Helper

/// Helper for encoding/decoding dynamic JSON
public struct AnyCodable: Codable, Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to encode value"
                )
            )
        }
    }
}
