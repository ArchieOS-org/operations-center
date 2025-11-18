//
//  TaskStatus.swift
//  OperationsCenterKit
//
//  Shared task status enum used by both Activity and AgentTask models
//  Consolidates duplicate TaskStatus definitions to follow DRY principle
//

import Foundation

/// Task status enum shared across Activity and AgentTask models
/// Matches database status values: OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED
public enum TaskStatus: String, Codable, Sendable {
    case open = "OPEN"
    case claimed = "CLAIMED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case failed = "FAILED"
    case cancelled = "CANCELLED"

    public var displayName: String {
        switch self {
        case .open: return "Open"
        case .claimed: return "Claimed"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

