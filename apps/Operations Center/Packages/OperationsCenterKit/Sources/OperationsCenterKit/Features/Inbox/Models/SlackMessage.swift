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
