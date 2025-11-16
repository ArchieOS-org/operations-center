//
//  Activity.swift
//  Operations Center
//
//  Data model for activities table
//

import Foundation

public struct Activity: Identifiable, Codable, Sendable {
    public let id: String
    public let listingId: String
    public let realtorId: String?
    public let name: String
    public let description: String?
    public let taskCategory: TaskCategory
    public var status: TaskStatus
    public let priority: Int
    public let visibilityGroup: VisibilityGroup
    public var assignedStaffId: String?
    public let dueDate: Date?
    public var claimedAt: Date?
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

        public var displayName: String {
            switch self {
            case .admin: return "Admin"
            case .marketing: return "Marketing"
            case .photo: return "Photo"
            case .staging: return "Staging"
            case .inspection: return "Inspection"
            case .other: return "Other"
            }
        }
    }

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

    public enum VisibilityGroup: String, Codable, Sendable {
        case both = "BOTH"
        case agent = "AGENT"
        case marketing = "MARKETING"
    }

    // MARK: - Initialization

    /// Memberwise initializer required for Codable types
    /// Codable synthesis only provides init(from: Decoder), not memberwise init
    public init(
        id: String,
        listingId: String,
        realtorId: String? = nil,
        name: String,
        description: String? = nil,
        taskCategory: TaskCategory,
        status: TaskStatus,
        priority: Int,
        visibilityGroup: VisibilityGroup,
        assignedStaffId: String? = nil,
        dueDate: Date? = nil,
        claimedAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        deletedBy: String? = nil,
        inputs: [String: AnyCodable]? = nil,
        outputs: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.listingId = listingId
        self.realtorId = realtorId
        self.name = name
        self.description = description
        self.taskCategory = taskCategory
        self.status = status
        self.priority = priority
        self.visibilityGroup = visibilityGroup
        self.assignedStaffId = assignedStaffId
        self.dueDate = dueDate
        self.claimedAt = claimedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.deletedBy = deletedBy
        self.inputs = inputs
        self.outputs = outputs
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

// MARK: - Mock Data

extension Activity {
    /// Mock data for testing and previews
    /// Context7 best practice: Keep mock data with the model
    /// Reference: swift-dependencies/Articles/LivePreviewTest.md
    /// Note: Using computed properties (var) instead of static constants (let) to ensure dates are always relative to "now"

    public static var mock1: Activity {
        Activity(
            id: "activity_001",
            listingId: "listing_001",
            realtorId: "realtor_001",
            name: "Professional Photography",
            description: "Schedule and complete professional photography for the listing",
            taskCategory: .photo,
            status: .open,
            priority: 100,
            visibilityGroup: .both,
            assignedStaffId: nil,
            dueDate: Date().addingTimeInterval(86400 * 2), // 2 days from now
            claimedAt: nil,
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 5),
            deletedAt: nil,
            deletedBy: nil,
            inputs: ["photographer": AnyCodable("John Smith Photography")],
            outputs: nil
        )
    }

    public static var mock2: Activity {
        Activity(
            id: "activity_002",
            listingId: "listing_002",
            realtorId: "realtor_002",
            name: "Social Media Campaign",
            description: "Launch Instagram and Facebook ads for new listing",
            taskCategory: .marketing,
            status: .claimed,
            priority: 80,
            visibilityGroup: .marketing,
            assignedStaffId: "staff_001",
            dueDate: Date().addingTimeInterval(86400 * 3), // 3 days from now
            claimedAt: Date().addingTimeInterval(-86400), // 1 day ago
            completedAt: nil,
            createdAt: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            updatedAt: Date().addingTimeInterval(-86400),
            deletedAt: nil,
            deletedBy: nil,
            inputs: ["budget": AnyCodable(500), "platforms": AnyCodable(["instagram", "facebook"])],
            outputs: nil
        )
    }

    public static var mock3: Activity {
        Activity(
            id: "activity_003",
            listingId: "listing_003",
            realtorId: "realtor_001",
            name: "Home Inspection Coordination",
            description: "Schedule and coordinate the home inspection",
            taskCategory: .inspection,
            status: .done,
            priority: 90,
            visibilityGroup: .agent,
            assignedStaffId: "staff_002",
            dueDate: Date().addingTimeInterval(-86400), // 1 day ago
            claimedAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            completedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            createdAt: Date().addingTimeInterval(-86400 * 10), // 10 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            deletedAt: nil,
            deletedBy: nil,
            inputs: ["inspector": AnyCodable("AAA Home Inspections")],
            outputs: ["report_url": AnyCodable("https://example.com/report.pdf")]
        )
    }
}

// MARK: - AnyCodable Helper

/// Helper for encoding/decoding dynamic JSON
/// @unchecked Sendable: Safe because value only crosses isolation boundaries via JSON serialization/deserialization
public struct AnyCodable: Codable, @unchecked Sendable {
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
