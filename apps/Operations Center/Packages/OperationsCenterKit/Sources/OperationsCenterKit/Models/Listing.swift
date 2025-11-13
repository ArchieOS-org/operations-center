//
//  Listing.swift
//  OperationsCenterKit
//
//  Data model for listings table
//

import Foundation

public struct Listing: Identifiable, Codable, Sendable {
    // MARK: - Properties

    public let id: String
    public let addressString: String
    public let status: String
    public let assignee: String?
    public let agentId: String?
    public let dueDate: Date?
    public let progress: Decimal?
    public let type: String?
    public let notes: String
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?

    // MARK: - Computed Properties

    /// Title for display - currently equals address, but can be reformatted later
    public var title: String {
        addressString
    }

    /// Whether this listing has been completed
    public var isComplete: Bool {
        completedAt != nil
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "listing_id"
        case addressString = "address_string"
        case status
        case assignee
        case agentId = "agent_id"
        case dueDate = "due_date"
        case progress
        case type
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case deletedAt = "deleted_at"
    }
}
