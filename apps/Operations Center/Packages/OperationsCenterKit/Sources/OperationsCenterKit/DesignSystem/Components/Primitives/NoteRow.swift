//
//  NoteRow.swift
//  OperationsCenterKit
//
//  Single note display with author, timestamp, and content
//

import SwiftUI

/// Displays a single note with author attribution and timestamp
public struct NoteRow: View {
    // MARK: - Properties

    let note: ListingNote

    // MARK: - Initialization

    public init(note: ListingNote) {
        self.note = note
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Author and timestamp
            HStack(spacing: Spacing.xs) {
                Text(note.createdBy ?? "Unknown")
                    .font(Typography.cardMeta)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("·")
                    .font(Typography.cardMeta)
                    .foregroundStyle(.tertiary)

                Text(note.createdAt, style: .relative)
                    .font(Typography.chipLabel)
                    .foregroundStyle(.secondary)
            }

            // Content
            Text(note.content)
                .font(Typography.body)
                .foregroundStyle(.primary)
        }
        .padding(Spacing.sm)
        .background(Colors.surfaceSecondary)
        .cornerRadius(CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        let author = note.createdBy ?? "Unknown"
        let time = note.createdAt.formatted(.relative(presentation: .named))
        return "\(author), \(time): \(note.content)"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        NoteRow(note: ListingNote(
            id: "1",
            listingId: "listing-1",
            content: "Need to schedule staging for next week",
            type: "general",
            createdBy: "Sarah Chen",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date().addingTimeInterval(-3600)
        ))

        NoteRow(note: ListingNote(
            id: "2",
            listingId: "listing-1",
            content: "Photos scheduled for Tuesday at 2pm. Photographer confirmed.",
            type: "general",
            createdBy: "Mike Torres",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400)
        ))

        NoteRow(note: ListingNote(
            id: "3",
            listingId: "listing-1",
            content: "Property showing went well. Buyer interested.",
            type: "general",
            createdBy: nil, // Test unknown author
            createdAt: Date().addingTimeInterval(-172800), // 2 days ago
            updatedAt: Date().addingTimeInterval(-172800)
        ))
    }
    .padding()
}
