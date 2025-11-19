//
//  ListingNote.swift
//  OperationsCenterKit
//
//  Data model for listing_notes table
//

import Foundation

public enum NoteType: String, Codable, Sendable {
    case general
    case inspection
    case showing
    case offer
    case followUp = "follow_up"
}

public struct ListingNote: Identifiable, Codable, Sendable {
    // MARK: - Properties

    public let id: String
    public let listingId: String
    public let content: String
    public let type: NoteType
    public let createdBy: String?
    public let createdByName: String?
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - Initialization

    /// Memberwise initializer required for Codable types
    public init(
        id: String,
        listingId: String,
        content: String,
        type: NoteType = .general,
        createdBy: String? = nil,
        createdByName: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.listingId = listingId
        self.content = content
        self.type = type
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "note_id"
        case listingId = "listing_id"
        case content
        case type
        case createdBy = "created_by"
        case createdByName = "created_by_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Mock Data

extension ListingNote {
    /// Mock data for testing and previews
    public static let mock1 = ListingNote(
        id: "note_001",
        listingId: "listing_001",
        content: "Initial listing prep meeting with agent. Property needs deep cleaning before photos.",
        type: .general,
        createdBy: "staff_001",
        createdByName: "Mike Torres",
        createdAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
        updatedAt: Date().addingTimeInterval(-86400 * 2)
    )

    public static let mock2 = ListingNote(
        id: "note_002",
        listingId: "listing_001",
        content: "Professional photography scheduled for Friday. Staging team confirmed for Thursday evening.",
        type: .general,
        createdBy: "staff_002",
        createdByName: "Sarah Chen",
        createdAt: Date().addingTimeInterval(-86400), // 1 day ago
        updatedAt: Date().addingTimeInterval(-86400)
    )

    public static let mock3 = ListingNote(
        id: "note_003",
        listingId: "listing_001",
        content: "Agent requested virtual tour option. Coordinate with video team.",
        type: .general,
        createdBy: "staff_003",
        createdByName: "Julia Martinez",
        createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
        updatedAt: Date().addingTimeInterval(-3600)
    )
}
