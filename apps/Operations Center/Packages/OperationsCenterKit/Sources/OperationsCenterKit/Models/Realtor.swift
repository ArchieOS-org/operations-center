//
//  Realtor.swift
//  OperationsCenterKit
//
//  Data model for realtors/agents table
//

import Foundation

public struct Realtor: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let email: String
    public let phone: String?
    public let companyName: String?
    public let licenseNumber: String?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id = "realtor_id"
        case name
        case email
        case phone
        case companyName = "company_name"
        case licenseNumber = "license_number"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
