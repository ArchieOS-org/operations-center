//
//  OCMessageRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Canonical "author + relative timestamp + text" row for notes and Slack messages
public struct OCMessageRow: View {
    private let author: String
    private let timestamp: Date
    private let content: String
    private let showBackground: Bool

    public init(
        author: String,
        timestamp: Date,
        content: String,
        showBackground: Bool = true
    ) {
        self.author = author
        self.timestamp = timestamp
        self.content = content
        self.showBackground = showBackground
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Author and timestamp header
            HStack(spacing: Spacing.xs) {
                Text(author)
                    .font(Typography.cardMeta)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)

                Text("·")
                    .font(Typography.cardMeta)
                    .foregroundStyle(.tertiary)

                Text(timestamp, style: .relative)
                    .font(Typography.chipLabel)
                    .foregroundStyle(Color.secondary)
            }

            // Message content
            Text(content)
                .font(Typography.body)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(showBackground ? Spacing.sm : 0)
        .background(showBackground ? Colors.surfaceSecondary : Color.clear)
        .cornerRadius(showBackground ? CornerRadius.sm : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        let timeFormatted = timestamp.formatted(.relative(presentation: .named))
        return "\(author), \(timeFormatted): \(content)"
    }
}

// MARK: - Model Initializers

extension OCMessageRow {
    /// Initialize from a ListingNote
    public init(note: ListingNote, showBackground: Bool = true) {
        self.author = note.createdBy ?? "Unknown"
        self.timestamp = note.createdAt
        self.content = note.content
        self.showBackground = showBackground
    }

    /// Initialize from a Slack message
    /// TODO: Add init(slackMessage: SlackMessage) once SlackMessage model is defined in Models/SlackMessage.swift
}