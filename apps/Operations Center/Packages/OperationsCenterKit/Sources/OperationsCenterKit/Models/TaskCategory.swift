//
//  TaskCategory.swift
//  OperationsCenterKit
//
//  Task categorization: Admin, Marketing, or uncategorized
//  Clean, simple, three-state model (admin/marketing/nil)
//

import Foundation

/// Task categorization for work items
/// Optional type: nil = uncategorized, .admin or .marketing = categorized
public enum TaskCategory: String, Codable, Sendable {
    case admin = "ADMIN"
    case marketing = "MARKETING"
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
