//
//  SlackMessage.swift
//  OperationsCenterKit
//
//  Represents a Slack message associated with a stray task
//

import Foundation

public struct SlackMessage: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let taskId: String
    public let channelId: String
    public let threadTs: String
    public let messageTs: String
    public let authorName: String
    public let text: String
    public let timestamp: Date

    public init(
        id: String,
        taskId: String,
        channelId: String,
        threadTs: String,
        messageTs: String,
        authorName: String,
        text: String,
        timestamp: Date
    ) {
        self.id = id
        self.taskId = taskId
        self.channelId = channelId
        self.threadTs = threadTs
        self.messageTs = messageTs
        self.authorName = authorName
        self.text = text
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case taskId = "task_id"
        case channelId = "channel_id"
        case threadTs = "thread_ts"
        case messageTs = "message_ts"
        case authorName = "author_name"
        case text
        case timestamp
    }
}

// MARK: - Mock Data

extension SlackMessage {
    /// Mock data for testing and previews
    public static let mock1 = SlackMessage(
        id: "msg_001",
        taskId: "stray_001",
        channelId: "C123ABC456",
        threadTs: "1234567890.123456",
        messageTs: "1234567890.123456",
        authorName: "Sarah Johnson",
        text: "We need to update the CRM with the latest client information from yesterday's meetings",
        timestamp: Date().addingTimeInterval(-86400 * 2) // 2 days ago
    )

    public static let mock2 = SlackMessage(
        id: "msg_002",
        taskId: "stray_003",
        channelId: "C789DEF012",
        threadTs: "1234567891.654321",
        messageTs: "1234567891.654321",
        authorName: "Mike Chen",
        text: "The portfolio photos from last week's shoots are ready for website upload",
        timestamp: Date().addingTimeInterval(-86400 * 4) // 4 days ago
    )
}
