//
//  Realtor.swift
//  OperationsCenterKit
//
//  Real estate agent/broker model
//  Maps to realtors table in Supabase (see migration 005_create_realtors_table.sql)
//

import Foundation

/// Real estate agent or broker (external client)
/// Note: Not Hashable due to flexible metadata field supporting arbitrary JSON
public struct Realtor: Identifiable, Codable, Sendable {
    // MARK: - Properties

    public let id: String
    public let email: String
    public let name: String
    public let phone: String?
    public let licenseNumber: String?
    public let brokerage: String?
    public let slackUserId: String?
    public let territories: [String]
    public let status: RealtorStatus
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let metadata: [String: AnyCodable]?

    // MARK: - Initialization

    public init(
        id: String,
        email: String,
        name: String,
        phone: String? = nil,
        licenseNumber: String? = nil,
        brokerage: String? = nil,
        slackUserId: String? = nil,
        territories: [String] = [],
        status: RealtorStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.brokerage = brokerage
        self.slackUserId = slackUserId
        self.territories = territories
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.metadata = metadata
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id = "realtor_id"
        case email
        case name
        case phone
        case licenseNumber = "license_number"
        case brokerage
        case slackUserId = "slack_user_id"
        case territories
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case metadata
    }
}

// MARK: - Realtor Status

public enum RealtorStatus: String, Codable, Sendable, CaseIterable {
    case active
    case inactive
    case suspended
    case pending

    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .suspended: return "Suspended"
        case .pending: return "Pending"
        }
    }
}

// MARK: - Mock Data

public extension Realtor {
    // Fixed epoch date for deterministic, repeatable test data
    private static let baseDate = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC

    static let mock1 = Realtor(
        id: "realtor_001",
        email: "sarah.johnson@example.com",
        name: "Sarah Johnson",
        phone: "+1-555-0123",
        licenseNumber: "CA-DRE-12345678",
        brokerage: "Prestige Realty Group",
        slackUserId: "U01ABC123",
        territories: ["San Francisco", "Oakland", "Berkeley"],
        status: .active,
        createdAt: baseDate.addingTimeInterval(-86400 * 90),  // 90 days before base
        updatedAt: baseDate.addingTimeInterval(-86400 * 5)    // 5 days before base
    )

    static let mock2 = Realtor(
        id: "realtor_002",
        email: "michael.chen@example.com",
        name: "Michael Chen",
        phone: "+1-555-0456",
        licenseNumber: "CA-DRE-87654321",
        brokerage: "Bay Area Properties",
        slackUserId: "U01DEF456",
        territories: ["San Jose", "Palo Alto", "Mountain View"],
        status: .active,
        createdAt: baseDate.addingTimeInterval(-86400 * 120), // 120 days before base
        updatedAt: baseDate.addingTimeInterval(-86400 * 2)    // 2 days before base
    )

    static let mock3 = Realtor(
        id: "realtor_003",
        email: "jessica.martinez@example.com",
        name: "Jessica Martinez",
        phone: "+1-555-0789",
        licenseNumber: "CA-DRE-11223344",
        brokerage: "Golden Gate Realty",
        territories: ["San Rafael", "Sausalito", "Mill Valley"],
        status: .inactive,
        createdAt: baseDate.addingTimeInterval(-86400 * 60),  // 60 days before base
        updatedAt: baseDate.addingTimeInterval(-86400 * 30)   // 30 days before base
    )

    static let mockList: [Realtor] = [mock1, mock2, mock3]
}
