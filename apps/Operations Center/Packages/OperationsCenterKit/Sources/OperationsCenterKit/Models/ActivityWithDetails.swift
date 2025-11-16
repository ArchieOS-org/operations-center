//
//  ActivityWithDetails.swift
//  OperationsCenterKit
//
//  Data structure for activities with associated listing and subtasks
//

import Foundation

/// Activity bundled with its listing details and subtasks
public struct ActivityWithDetails: Sendable {
    public let task: Activity
    public let listing: Listing
    public let subtasks: [Subtask]

    public init(task: Activity, listing: Listing, subtasks: [Subtask]) {
        self.task = task
        self.listing = listing
        self.subtasks = subtasks
    }
}
