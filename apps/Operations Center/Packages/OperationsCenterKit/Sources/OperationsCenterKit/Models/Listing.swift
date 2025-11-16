//
//  Listing.swift
//  OperationsCenterKit
//
//  Data model for listings table
//

import Foundation
import SwiftUI

// MARK: - ListingType

/// Enum representing the type of listing
public enum ListingType: String, Codable, Sendable {
    case sale = "SALE"
    case rental = "RENTAL"
    case commercial = "COMMERCIAL"
    case residential = "RESIDENTIAL"

    /// Color associated with this listing type
    public var color: Color {
        switch self {
        case .sale:
            return .blue
        case .rental:
            return .purple
        case .commercial:
            return .orange
        case .residential:
            return .green
        }
    }
}

// MARK: - Listing

public struct Listing: Identifiable, Codable, Sendable {
    // MARK: - Properties

    public let id: String
    public let addressString: String
    public let status: String
    public let assignee: String?
    public let realtorId: String?
    public let dueDate: Date?
    public let progress: Decimal?
    public let type: String?
    public let notes: String
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?

    // MARK: - Initialization

    /// Memberwise initializer required for Codable types
    public init(
        id: String,
        addressString: String,
        status: String,
        assignee: String? = nil,
        realtorId: String? = nil,
        dueDate: Date? = nil,
        progress: Decimal? = nil,
        type: String? = nil,
        notes: String,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.addressString = addressString
        self.status = status
        self.assignee = assignee
        self.realtorId = realtorId
        self.dueDate = dueDate
        self.progress = progress
        self.type = type
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
    }

    // MARK: - Computed Properties

    /// Title for display - currently equals address, but can be reformatted later
    public var title: String {
        addressString
    }

    /// Whether this listing has been completed
    public var isComplete: Bool {
        completedAt != nil
    }

    /// Parsed listing type from the underlying string value
    public var listingType: ListingType? {
        guard let type else { return nil }
        return ListingType(rawValue: type.uppercased())
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "listing_id"
        case addressString = "address_string"
        case status
        case assignee
        case realtorId = "realtor_id"
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

// MARK: - Mock Data

extension Listing {
    /// Mock data for testing and previews
    /// Context7 best practice: Keep mock data with the model
    /// Note: Using computed properties (var) instead of static constants (let) to ensure dates are always relative to "now"

    public static var mock1: Listing {
        Listing(
            id: "listing_001",
            addressString: "123 Main St, San Francisco, CA 94102",
            status: "ACTIVE",
            assignee: "staff_001",
            realtorId: "realtor_001",
            dueDate: Date().addingTimeInterval(86400 * 7), // 7 days from now
            progress: 0.45,
            type: "SALE",
            notes: "Prime location, needs staging",
            createdAt: Date().addingTimeInterval(-86400 * 14), // 14 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 1),
            completedAt: nil,
            deletedAt: nil
        )
    }

    public static var mock2: Listing {
        Listing(
            id: "listing_002",
            addressString: "456 Oak Ave, Palo Alto, CA 94301",
            status: "PENDING",
            assignee: "staff_002",
            realtorId: "realtor_002",
            dueDate: Date().addingTimeInterval(86400 * 14), // 14 days from now
            progress: 0.20,
            type: "RENTAL",
            notes: "Luxury rental, professional photos required",
            createdAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            completedAt: nil,
            deletedAt: nil
        )
    }

    public static var mock3: Listing {
        Listing(
            id: "listing_003",
            addressString: "789 Market St, San Jose, CA 95113",
            status: "COMPLETED",
            assignee: "staff_001",
            realtorId: "realtor_001",
            dueDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            progress: 1.0,
            type: "SALE",
            notes: "Successfully sold above asking price",
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 3),
            completedAt: Date().addingTimeInterval(-86400 * 3),
            deletedAt: nil
        )
    }
}
