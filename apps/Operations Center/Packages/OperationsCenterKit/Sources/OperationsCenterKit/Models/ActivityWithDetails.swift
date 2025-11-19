//
//  ActivityWithDetails.swift
//  OperationsCenterKit
//
//  Data structure for activities with associated listing
//

import Foundation

/// Activity bundled with its listing details
public struct ActivityWithDetails: Sendable {
    public let task: Activity
    public let listing: Listing

    public init(task: Activity, listing: Listing) {
        self.task = task
        self.listing = listing
    }
}
