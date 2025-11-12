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
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - Nested Types

    public enum StaffRole: String, Codable, Sendable {
        case admin = "ADMIN"
        case manager = "MANAGER"
        case staff = "STAFF"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "staff_id"
        case name
        case email
        case phone
        case role
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
