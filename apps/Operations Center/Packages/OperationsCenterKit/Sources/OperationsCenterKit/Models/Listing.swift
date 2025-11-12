//
//  Listing.swift
//  OperationsCenterKit
//
//  Data model for listings table
//

import Foundation

public struct Listing: Identifiable, Codable, Sendable {
    public let id: String
    public let address: String
    public let city: String?
    public let state: String?
    public let zipCode: String?
    public let realtorId: String
    public let status: ListingStatus
    public let listPrice: Decimal?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?

    // MARK: - Nested Types

    public enum ListingStatus: String, Codable, Sendable {
        case active = "ACTIVE"
        case pending = "PENDING"
        case sold = "SOLD"
        case cancelled = "CANCELLED"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "listing_id"
        case address
        case city
        case state
        case zipCode = "zip_code"
        case realtorId = "realtor_id"
        case status
        case listPrice = "list_price"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}
