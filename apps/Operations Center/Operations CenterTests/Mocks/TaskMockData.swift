//
//  TaskMockData.swift
//  Operations Center Tests
//
//  Realistic mock data for development and testing
//  Diverse scenarios: overdue tasks, recent tasks, various categories
//

import Foundation
import OperationsCenterKit

/// Collection of realistic mock task data
struct TaskMockData {
    let tasks: [AgentTask]
    let activities: [Activity]
    let listings: [String: Listing] // listingId -> Listing
    let slackMessages: [String: [SlackMessage]]
    let subtasks: [String: [Subtask]]

    init() {
        let now = Date()

        // MARK: - Agent Tasks (5 diverse examples)

        let agentTask1 = AgentTask(
            id: "agent-task-1",
            realtorId: "realtor-001",
            name: "Update CRM with Q4 contacts",
            description: "Need to import all new contacts from networking events into CRM",
            taskCategory: .admin,
            status: .open,
            priority: 2,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(-2 * 24 * 3600), // 2 days overdue
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-5 * 24 * 3600),
            updatedAt: now.addingTimeInterval(-5 * 24 * 3600),
            deletedAt: nil,
            deletedBy: nil
        )

        let agentTask2 = AgentTask(
            id: "agent-task-2",
            realtorId: "realtor-001",
            name: "Schedule photoshoot for portfolio",
            description: "Need professional photos of recent staging work",
            taskCategory: .photo,
            status: .open,
            priority: 1,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(3 * 24 * 3600), // 3 days from now
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-1 * 24 * 3600),
            updatedAt: now.addingTimeInterval(-1 * 24 * 3600),
            deletedAt: nil,
            deletedBy: nil
        )

        let agentTask3 = AgentTask(
            id: "agent-task-3",
            realtorId: "realtor-002",
            name: "Create Instagram reels from open house",
            description: "Edit video clips from last weekend's open house",
            taskCategory: .marketing,
            status: .open,
            priority: 3,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(1 * 24 * 3600), // Tomorrow
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-6 * 3600),
            updatedAt: now.addingTimeInterval(-6 * 3600),
            deletedAt: nil,
            deletedBy: nil
        )

        let agentTask4 = AgentTask(
            id: "agent-task-4",
            realtorId: "realtor-001",
            name: "Review inspection report formatting",
            description: "New inspector using different template format",
            taskCategory: .inspection,
            status: .open,
            priority: 2,
            assignedStaffId: nil,
            dueDate: nil,
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-3 * 3600),
            updatedAt: now.addingTimeInterval(-3 * 3600),
            deletedAt: nil,
            deletedBy: nil
        )

        let agentTask5 = AgentTask(
            id: "agent-task-5",
            realtorId: "realtor-003",
            name: "Coordinate furniture rental for staging",
            description: "Client wants modern farmhouse aesthetic",
            taskCategory: .staging,
            status: .open,
            priority: 1,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(5 * 24 * 3600), // 5 days from now
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-12 * 3600),
            updatedAt: now.addingTimeInterval(-12 * 3600),
            deletedAt: nil,
            deletedBy: nil
        )

        tasks = [agentTask1, agentTask2, agentTask3, agentTask4, agentTask5]

        // MARK: - Activities (4 diverse examples)

        let listingTask1 = Activity(
            id: "listing-1",
            listingId: "listing-001",
            realtorId: "realtor-001",
            name: "123 Maple Street pre-listing prep",
            description: "Prepare property for market launch",
            taskCategory: .admin,
            status: .open,
            priority: 1,
            visibilityGroup: .both,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(7 * 24 * 3600),
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-2 * 24 * 3600),
            updatedAt: now.addingTimeInterval(-2 * 24 * 3600),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        )

        let listingTask2 = Activity(
            id: "listing-2",
            listingId: "listing-002",
            realtorId: "realtor-002",
            name: "456 Oak Avenue marketing campaign",
            description: "Launch comprehensive digital marketing",
            taskCategory: .marketing,
            status: .open,
            priority: 2,
            visibilityGroup: .marketing,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(2 * 24 * 3600),
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-1 * 24 * 3600),
            updatedAt: now.addingTimeInterval(-1 * 24 * 3600),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        )

        let listingTask3 = Activity(
            id: "listing-3",
            listingId: "listing-003",
            realtorId: "realtor-001",
            name: "789 Pine Road inspection follow-up",
            description: "Address inspection items before closing",
            taskCategory: .inspection,
            status: .open,
            priority: 1,
            visibilityGroup: .agent,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(-1 * 24 * 3600), // Overdue
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-4 * 24 * 3600),
            updatedAt: now.addingTimeInterval(-4 * 24 * 3600),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        )

        let listingTask4 = Activity(
            id: "listing-4",
            listingId: "listing-004",
            realtorId: "realtor-003",
            name: "321 Elm Court professional photography",
            description: "Schedule and execute property photoshoot",
            taskCategory: .photo,
            status: .open,
            priority: 2,
            visibilityGroup: .both,
            assignedStaffId: nil,
            dueDate: now.addingTimeInterval(4 * 24 * 3600),
            claimedAt: nil,
            completedAt: nil,
            createdAt: now.addingTimeInterval(-18 * 3600),
            updatedAt: now.addingTimeInterval(-18 * 3600),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        )

        activities = [listingTask1, listingTask2, listingTask3, listingTask4]

        // MARK: - Listings (property data)

        listings = [
            "listing-001": Listing(
                id: "listing-001",
                addressString: "123 Maple Street",
                status: "new",
                assignee: nil,
                realtorId: "realtor-001",
                dueDate: now.addingTimeInterval(7 * 24 * 3600),
                progress: 0.0,
                type: "RESIDENTIAL",
                notes: "New listing - needs initial walkthrough and assessment",
                createdAt: now.addingTimeInterval(-2 * 24 * 3600),
                updatedAt: now.addingTimeInterval(-2 * 24 * 3600),
                completedAt: nil,
                deletedAt: nil
            ),
            "listing-002": Listing(
                id: "listing-002",
                addressString: "456 Oak Avenue",
                status: "in_progress",
                assignee: nil,
                realtorId: "realtor-002",
                dueDate: now.addingTimeInterval(2 * 24 * 3600),
                progress: 35.0,
                type: "COMMERCIAL",
                notes: "Marketing campaign underway. Waiting on professional photos from last week's shoot.",
                createdAt: now.addingTimeInterval(-1 * 24 * 3600),
                updatedAt: now.addingTimeInterval(-1 * 24 * 3600),
                completedAt: nil,
                deletedAt: nil
            ),
            "listing-003": Listing(
                id: "listing-003",
                addressString: "789 Pine Road",
                status: "in_progress",
                assignee: nil,
                realtorId: "realtor-001",
                dueDate: now.addingTimeInterval(-1 * 24 * 3600),
                progress: 80.0,
                type: "RESIDENTIAL",
                notes: "Inspection items need addressing before closing. Window pane and HVAC repairs pending.",
                createdAt: now.addingTimeInterval(-4 * 24 * 3600),
                updatedAt: now.addingTimeInterval(-4 * 24 * 3600),
                completedAt: nil,
                deletedAt: nil
            ),
            "listing-004": Listing(
                id: "listing-004",
                addressString: "321 Elm Court",
                status: "new",
                assignee: nil,
                realtorId: "realtor-003",
                dueDate: now.addingTimeInterval(10 * 24 * 3600),
                progress: 10.0,
                type: "LUXURY",
                notes: "High-end property. Photographer booked for next week. Need to coordinate with homeowner.",
                createdAt: now.addingTimeInterval(-3 * 24 * 3600),
                updatedAt: now.addingTimeInterval(-3 * 24 * 3600),
                completedAt: nil,
                deletedAt: nil
            )
        ]

        // MARK: - Slack Messages

        slackMessages = [
            "agent-task-1": [
                SlackMessage(
                    id: "msg-1",
                    taskId: "agent-task-1",
                    channelId: "C123ABC",
                    threadTs: "1699564800.123456",
                    messageTs: "1699564800.123456",
                    authorName: "Sarah Chen",
                    text: "We collected about 50 new contacts at the real estate conference. Need these in CRM ASAP.",
                    timestamp: now.addingTimeInterval(-5 * 24 * 3600)
                ),
                SlackMessage(
                    id: "msg-2",
                    taskId: "agent-task-1",
                    channelId: "C123ABC",
                    threadTs: "1699564800.123456",
                    messageTs: "1699651200.789012",
                    authorName: "Mike Torres",
                    text: "I have the business cards scanned. Should I send the PDF or enter manually?",
                    timestamp: now.addingTimeInterval(-4 * 24 * 3600)
                )
            ],
            "agent-task-2": [
                SlackMessage(
                    id: "msg-3",
                    taskId: "agent-task-2",
                    channelId: "C456DEF",
                    threadTs: "1699824000.345678",
                    messageTs: "1699824000.345678",
                    authorName: "Lisa Park",
                    text: "The staging work at Oakwood came out amazing. Let's get pro photos for the portfolio.",
                    timestamp: now.addingTimeInterval(-1 * 24 * 3600)
                )
            ],
            "agent-task-3": [
                SlackMessage(
                    id: "msg-4",
                    taskId: "agent-task-3",
                    channelId: "C789GHI",
                    threadTs: "1699887600.901234",
                    messageTs: "1699887600.901234",
                    authorName: "David Kim",
                    text: "Got some great clips from the open house yesterday. Lots of buyer engagement!",
                    timestamp: now.addingTimeInterval(-6 * 3600)
                ),
                SlackMessage(
                    id: "msg-5",
                    taskId: "agent-task-3",
                    channelId: "C789GHI",
                    threadTs: "1699887600.901234",
                    messageTs: "1699891200.567890",
                    authorName: "Jessica Liu",
                    text: "I can edit these into 3-4 short reels. Need them by end of week?",
                    timestamp: now.addingTimeInterval(-5 * 3600)
                )
            ],
            "agent-task-4": [
                SlackMessage(
                    id: "msg-6",
                    taskId: "agent-task-4",
                    channelId: "C101JKL",
                    threadTs: "1699898400.123789",
                    messageTs: "1699898400.123789",
                    authorName: "Tom Anderson",
                    text: "New inspector sent the report in a different format. Can someone check if this works for our workflow?",
                    timestamp: now.addingTimeInterval(-3 * 3600)
                )
            ]
        ]

        // MARK: - Subtasks

        subtasks = [
            "listing-1": [
                Subtask(
                    id: "sub-1",
                    parentTaskId: "listing-1",
                    name: "Deep clean all rooms",
                    isCompleted: true,
                    completedAt: now.addingTimeInterval(-1 * 24 * 3600),
                    createdAt: now.addingTimeInterval(-2 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-2",
                    parentTaskId: "listing-1",
                    name: "Touch up paint in living room",
                    isCompleted: true,
                    completedAt: now.addingTimeInterval(-1 * 24 * 3600),
                    createdAt: now.addingTimeInterval(-2 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-3",
                    parentTaskId: "listing-1",
                    name: "Landscape front yard",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-2 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-4",
                    parentTaskId: "listing-1",
                    name: "Stage master bedroom",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-2 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-5",
                    parentTaskId: "listing-1",
                    name: "Schedule professional photos",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-2 * 24 * 3600)
                )
            ],
            "listing-2": [
                Subtask(
                    id: "sub-6",
                    parentTaskId: "listing-2",
                    name: "Create social media posts",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-1 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-7",
                    parentTaskId: "listing-2",
                    name: "Design email blast",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-1 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-8",
                    parentTaskId: "listing-2",
                    name: "Update MLS listing",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-1 * 24 * 3600)
                )
            ],
            "listing-3": [
                Subtask(
                    id: "sub-9",
                    parentTaskId: "listing-3",
                    name: "Fix loose handrail on stairs",
                    isCompleted: true,
                    completedAt: now.addingTimeInterval(-2 * 24 * 3600),
                    createdAt: now.addingTimeInterval(-4 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-10",
                    parentTaskId: "listing-3",
                    name: "Replace cracked window pane",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-4 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-11",
                    parentTaskId: "listing-3",
                    name: "Service HVAC system",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-4 * 24 * 3600)
                ),
                Subtask(
                    id: "sub-12",
                    parentTaskId: "listing-3",
                    name: "Re-inspect after repairs",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-4 * 24 * 3600)
                )
            ],
            "listing-4": [
                Subtask(
                    id: "sub-13",
                    parentTaskId: "listing-4",
                    name: "Book photographer",
                    isCompleted: true,
                    completedAt: now.addingTimeInterval(-12 * 3600),
                    createdAt: now.addingTimeInterval(-18 * 3600)
                ),
                Subtask(
                    id: "sub-14",
                    parentTaskId: "listing-4",
                    name: "Coordinate with homeowner",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-18 * 3600)
                ),
                Subtask(
                    id: "sub-15",
                    parentTaskId: "listing-4",
                    name: "Prepare shot list",
                    isCompleted: false,
                    completedAt: nil,
                    createdAt: now.addingTimeInterval(-18 * 3600)
                )
            ]
        ]
    }
}
