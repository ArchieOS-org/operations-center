//
//  NotesSection.swift
//  OperationsCenterKit
//
//  Notes list with input field - zero lag, zero complexity
//

import SwiftUI

/// Notes section - type, submit, done
public struct NotesSection: View {
    let notes: [ListingNote]
    let onAddNote: (String) -> Void

    @State private var newNoteText = ""
    @FocusState private var isInputFocused: Bool

    public init(
        notes: [ListingNote],
        onAddNote: @escaping (String) -> Void
    ) {
        self.notes = notes
        self.onAddNote = onAddNote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notes")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)

            TextField("Add a note...", text: $newNoteText, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...3)
                .padding(Spacing.sm)
                .background(Colors.surfaceTertiary)
                .cornerRadius(CornerRadius.sm)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit {
                    submitNote()
                }

            if !notes.isEmpty {
                VStack(spacing: Spacing.sm) {
                    ForEach(notes) { note in
                        NoteRow(note: note)
                    }
                }
            }
        }
    }

    private func submitNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        onAddNote(trimmed)
        newNoteText = ""
        isInputFocused = true
    }
}

// MARK: - Preview

#Preview("Empty Notes") {
    @Previewable @State var notes: [ListingNote] = []

    NotesSection(notes: notes) { content in
        let newNote = ListingNote(
            id: UUID().uuidString,
            listingId: "listing-1",
            content: content,
            type: "general",
            createdBy: "Current User",
            createdAt: Date(),
            updatedAt: Date()
        )
        notes.append(newNote)
    }
    .padding()
}

#Preview("With Notes") {
    @Previewable @State var notes: [ListingNote] = [
        ListingNote(
            id: "1",
            listingId: "listing-1",
            content: "Need staging by Friday",
            type: "general",
            createdBy: "Mike Torres",
            createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
            updatedAt: Date().addingTimeInterval(-7200)
        ),
        ListingNote(
            id: "2",
            listingId: "listing-1",
            content: "Photos scheduled for Tuesday",
            type: "general",
            createdBy: "Sarah Chen",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date().addingTimeInterval(-3600)
        )
    ]

    NotesSection(notes: notes) { content in
        let newNote = ListingNote(
            id: UUID().uuidString,
            listingId: "listing-1",
            content: content,
            type: "general",
            createdBy: "Current User",
            createdAt: Date(),
            updatedAt: Date()
        )
        notes.append(newNote)
    }
    .padding()
}
