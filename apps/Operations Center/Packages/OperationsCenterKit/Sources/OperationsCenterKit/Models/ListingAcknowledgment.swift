//
//  ListingAcknowledgment.swift
//  OperationsCenterKit
//
//  Data model for listing_acknowledgments table
//  Tracks per-user acknowledgment of listings
//

import Foundation

public struct ListingAcknowledgment: Identifiable, Codable, Sendable {
    public let id: String
    public let listingId: String
    public let staffId: String
    public let acknowledgedAt: Date
    public let acknowledgedFrom: AcknowledgmentSource?

    // MARK: - Nested Types

    public enum AcknowledgmentSource: String, Codable, Sendable {
        case mobile = "mobile"
        case web = "web"
        case notification = "notification"
    }

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        listingId: String,
        staffId: String,
        acknowledgedAt: Date = Date(),
        acknowledgedFrom: AcknowledgmentSource? = .mobile
    ) {
        self.id = id
        self.listingId = listingId
        self.staffId = staffId
        self.acknowledgedAt = acknowledgedAt
        self.acknowledgedFrom = acknowledgedFrom
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case staffId = "staff_id"
        case acknowledgedAt = "acknowledged_at"
        case acknowledgedFrom = "acknowledged_from"
    }
}

// MARK: - Mock Data

extension ListingAcknowledgment {
    public static var mock1: ListingAcknowledgment {
        ListingAcknowledgment(
            id: UUID().uuidString,
            listingId: "listing_001",
            staffId: "staff_001",
            acknowledgedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            acknowledgedFrom: .mobile
        )
    }

    public static var mock2: ListingAcknowledgment {
        ListingAcknowledgment(
            id: UUID().uuidString,
            listingId: "listing_002",
            staffId: "staff_002",
            acknowledgedAt: Date().addingTimeInterval(-7200), // 2 hours ago
            acknowledgedFrom: .web
        )
    }
}
