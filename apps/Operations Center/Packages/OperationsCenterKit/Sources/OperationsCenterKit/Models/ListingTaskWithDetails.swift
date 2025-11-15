//
//  ListingTaskWithDetails.swift
//  OperationsCenterKit
//
//  Data structure for listing tasks with associated listing and subtasks
//

import Foundation

/// Listing task bundled with its listing details and subtasks
public struct ListingTaskWithDetails: Sendable {
    public let task: ListingTask
    public let listing: Listing
    public let subtasks: [Subtask]

    public init(task: ListingTask, listing: Listing, subtasks: [Subtask]) {
        self.task = task
        self.listing = listing
        self.subtasks = subtasks
    }
}
