//
//  NoteRow.swift
//  OperationsCenterKit
//
//  Single note display - author, timestamp, content
//  Zero complexity, zero lag
//

import SwiftUI

/// Single note row - clean and fast
public struct NoteRow: View {
    let note: ListingNote

    public init(note: ListingNote) {
        self.note = note
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text(note.createdByName ?? "Unknown")
                    .font(Typography.cardMeta)
                    .fontWeight(.medium)

                Text("·")
                    .foregroundStyle(.tertiary)

                Text(note.createdAt, style: .relative)
                    .font(Typography.chipLabel)
                    .foregroundStyle(.secondary)
            }

            Text(note.content)
                .font(Typography.body)
        }
        .padding(Spacing.sm)
        .background(Colors.surfaceSecondary)
        .cornerRadius(CornerRadius.sm)
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
            createdBy: "staff_001",
            createdByName: "Sarah Chen",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date().addingTimeInterval(-3600)
        ))

        NoteRow(note: ListingNote(
            id: "2",
            listingId: "listing-1",
            content: "Photos scheduled for Tuesday at 2pm. Photographer confirmed.",
            type: "general",
            createdBy: "staff_002",
            createdByName: "Mike Torres",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400)
        ))

        NoteRow(note: ListingNote(
            id: "3",
            listingId: "listing-1",
            content: "Property showing went well. Buyer interested.",
            type: "general",
            createdBy: "staff_003",
            createdByName: nil, // Test unknown author
            createdAt: Date().addingTimeInterval(-172800), // 2 days ago
            updatedAt: Date().addingTimeInterval(-172800)
        ))
    }
    .padding()
}
