//
//  TaskStatusColors.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Centralized status-to-color mapping for task status indicators
/// Used by OCActivityRow and OCTaskRow to maintain consistent status colors

extension Activity.TaskStatus {
    /// Color for status indicator dot
    var statusColor: Color {
        switch self {
        case .open:
            return Colors.statusOpen
        case .claimed:
            return Colors.statusClaimed
        case .inProgress:
            return Colors.statusInProgress
        case .done:
            return Colors.statusCompleted
        case .failed:
            return Colors.statusFailed
        case .cancelled:
            return Colors.statusCancelled
        }
    }
}

extension AgentTask.TaskStatus {
    /// Color for status indicator dot
    var statusColor: Color {
        switch self {
        case .open:
            return Colors.statusOpen
        case .claimed:
            return Colors.statusClaimed
        case .inProgress:
            return Colors.statusInProgress
        case .done:
            return Colors.statusCompleted
        case .failed:
            return Colors.statusFailed
        case .cancelled:
            return Colors.statusCancelled
        }
    }
}
