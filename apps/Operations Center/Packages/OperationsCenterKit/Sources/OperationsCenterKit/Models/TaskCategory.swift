//
//  TaskCategory.swift
//  OperationsCenterKit
//
//  Task categorization: Admin, Marketing, Photo, Staging, Inspection, Other
//  Matches database check constraint from migration 017
//

import Foundation

/// Task categorization for work items
/// Matches database check constraint: ADMIN, MARKETING, PHOTO, STAGING, INSPECTION, OTHER
public enum TaskCategory: String, Codable, Sendable {
    case admin = "ADMIN"
    case marketing = "MARKETING"
    case photo = "PHOTO"
    case staging = "STAGING"
    case inspection = "INSPECTION"
    case other = "OTHER"
}

// MARK: - Optional Extensions

extension Optional where Wrapped == TaskCategory {
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .marketing:
            return "Marketing"
        case .photo:
            return "Photo"
        case .staging:
            return "Staging"
        case .inspection:
            return "Inspection"
        case .other:
            return "Other"
        case nil:
            return "Uncategorized"
        }
    }

    /// Check if task is admin category
    public var isAdmin: Bool {
        self == .admin
    }

    /// Check if task is marketing category
    public var isMarketing: Bool {
        self == .marketing
    }

    /// Check if task has any category assigned
    public var isCategorized: Bool {
        self != nil
    }

    /// Check if task is uncategorized
    public var isUncategorized: Bool {
        self == nil
    }
}
