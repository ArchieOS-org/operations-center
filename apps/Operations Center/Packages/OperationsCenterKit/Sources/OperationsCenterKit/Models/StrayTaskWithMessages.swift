//
//  StrayTaskWithMessages.swift
//  OperationsCenterKit
//
//  Data structure for stray tasks with their associated Slack messages
//

import Foundation

/// Stray task bundled with its Slack message thread
public struct StrayTaskWithMessages: Sendable {
    public let task: StrayTask
    public let messages: [SlackMessage]

    public init(task: StrayTask, messages: [SlackMessage]) {
        self.task = task
        self.messages = messages
    }
}
