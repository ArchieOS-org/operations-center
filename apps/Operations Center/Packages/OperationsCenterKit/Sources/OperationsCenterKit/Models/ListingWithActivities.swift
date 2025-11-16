//
//  ListingWithActivities.swift
//  OperationsCenterKit
//
//  Composite model per TASK_MANAGEMENT_SPEC.md
//  Bundles a Listing with its Activities (ListingTasks), Slack messages, and notes
//

import Foundation

/// Listing bundled with all its related Activities and metadata
///
/// Per TASK_MANAGEMENT_SPEC.md (lines 16-37):
/// - Listings have predefined Activities based on type
/// - Spawned from Slack messages
/// - Can have Tasks assigned to it
/// - When ALL Activities complete → Moves to Logbook
public struct ListingWithActivities: Sendable, Identifiable {
    /// The core listing entity
    public let listing: Listing

    /// Activities (ListingTask) belonging to this listing
    /// Per spec: "Activities ALWAYS belong to a Listing" (line 42)
    /// Per spec: "Pre-set as Marketing or Admin (cannot toggle)" (line 55)
    public let activities: [ListingTask]

    /// Slack messages that spawned this listing
    /// Per spec line 29: "Slack messages that spawned it"
    public let slackMessages: [SlackMessage]

    // MARK: - Identifiable

    public var id: String {
        listing.id
    }

    // MARK: - Initialization

    public init(
        listing: Listing,
        activities: [ListingTask],
        slackMessages: [SlackMessage]
    ) {
        self.listing = listing
        self.activities = activities
        self.slackMessages = slackMessages
    }

    // MARK: - Computed Properties

    /// All activities are complete when every activity has a completedAt date
    /// Per spec line 36: "When ALL Activities are complete → Moves to Logbook"
    public var allActivitiesComplete: Bool {
        !activities.isEmpty && activities.allSatisfy { $0.completedAt != nil }
    }

    /// Marketing activities only
    /// Per spec line 358: "Marketing Activities (separate section)"
    public var marketingActivities: [ListingTask] {
        activities.filter { $0.taskCategory == .marketing }
    }

    /// Admin activities only
    /// Per spec line 359: "Admin Activities (separate section)"
    public var adminActivities: [ListingTask] {
        activities.filter { $0.taskCategory == .admin }
    }

    /// Completed activities (moved to bottom, crossed out)
    /// Per spec line 61: "When completed: move to bottom of list, show as crossed out"
    public var completedActivities: [ListingTask] {
        activities.filter { $0.completedAt != nil }
    }

    /// Incomplete activities (active work)
    public var incompleteActivities: [ListingTask] {
        activities.filter { $0.completedAt == nil }
    }
}

// MARK: - Mock Data

extension ListingWithActivities {
    /// Mock data for testing and previews
    /// Following Context7 best practice: Keep mock data with the model

    public static let mock1 = ListingWithActivities(
        listing: .mock1,
        activities: [
            ListingTask.mock1,
            ListingTask.mock2
        ],
        slackMessages: []
    )

    public static let mock2 = ListingWithActivities(
        listing: .mock2,
        activities: [
            ListingTask.mock3
        ],
        slackMessages: []
    )
}
