//
//  TaskWithMessages.swift
//  OperationsCenterKit
//
//  Data structure for tasks with their associated Slack messages
//

import Foundation

/// Task bundled with its Slack message thread
public struct TaskWithMessages: Sendable {
    public let task: AgentTask
    public let messages: [SlackMessage]

    public init(task: AgentTask, messages: [SlackMessage]) {
        self.task = task
        self.messages = messages
    }
}
