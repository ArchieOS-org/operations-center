//
//  Staff.swift
//  OperationsCenterKit
//
//  Data model for staff table
//

import Foundation

public struct Staff: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let email: String
    public let phone: String?
    public let role: StaffRole
    public let status: String
    public let slackUserId: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let metadata: [String: String]?

    // MARK: - Computed Properties
    
    /// Helper to check if staff is active based on status field
    public var isActive: Bool {
        status.lowercased() == "active"
    }

    // MARK: - Nested Types

    public enum StaffRole: String, Codable, Sendable {
        case admin = "admin"
        case operations = "operations"
        case marketing = "marketing"
        case support = "support"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "staff_id"
        case name
        case email
        case phone
        case role
        case status
        case slackUserId = "slack_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case metadata
    }
}
