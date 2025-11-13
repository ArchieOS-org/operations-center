//
//  SlackMessagesSection.swift
//  OperationsCenterKit
//
//  Displays Slack messages for stray tasks in expanded state
//

import SwiftUI

/// Section displaying Slack conversation messages
struct SlackMessagesSection: View {
    // MARK: - Properties

    let messages: [SlackMessage]

    // MARK: - Body

    var body: some View {
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Section header
                Text("Slack Messages")
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 4)

                // Messages
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        messageRow(message)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private func messageRow(_ message: SlackMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Author and timestamp
            HStack(spacing: 8) {
                Text(message.authorName)
                    .font(Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message.timestamp.formatted(.relative(presentation: .named)))
                    .font(Typography.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Message text
            Text(message.text)
                .font(Typography.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Preview

#Preview {
    let mockMessages = [
        SlackMessage(
            id: "1",
            taskId: "task-1",
            channelId: "C123",
            threadTs: "1699564800.123456",
            messageTs: "1699564800.123456",
            authorName: "Sarah Chen",
            text: "We collected about 50 new contacts at the real estate conference. Need these in CRM ASAP.",
            timestamp: Date().addingTimeInterval(-5 * 24 * 3600)
        ),
        SlackMessage(
            id: "2",
            taskId: "task-1",
            channelId: "C123",
            threadTs: "1699564800.123456",
            messageTs: "1699651200.789012",
            authorName: "Mike Torres",
            text: "I have the business cards scanned. Should I send the PDF or enter manually?",
            timestamp: Date().addingTimeInterval(-4 * 24 * 3600)
        )
    ]

    SlackMessagesSection(messages: mockMessages)
        .padding()
}
