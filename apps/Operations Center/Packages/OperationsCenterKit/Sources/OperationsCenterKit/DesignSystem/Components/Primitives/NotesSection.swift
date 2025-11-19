//
//  NotesSection.swift
//  OperationsCenterKit
//
//  Notes list with input field - pure rendering, zero complexity
//  Parent owns state and submission logic
//

import SwiftUI

/// Notes section - pure rendering component
/// Parent manages input state and handles submission with optimistic updates
public struct NotesSection: View {
    let notes: [ListingNote]
    @Binding var inputText: String
    let onSubmit: () -> Void

    @FocusState private var isInputFocused: Bool

    public init(
        notes: [ListingNote],
        inputText: Binding<String>,
        onSubmit: @escaping () -> Void
    ) {
        self.notes = notes
        self._inputText = inputText
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notes")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)

            TextField("Add a note...", text: $inputText)
                .font(Typography.body)
                .lineLimit(1)
                .padding(Spacing.sm)
                .background(Colors.surfaceTertiary)
                .cornerRadius(CornerRadius.sm)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit(onSubmit)

            if !notes.isEmpty {
                VStack(spacing: Spacing.sm) {
                    ForEach(notes) { note in
                        NoteRow(note: note)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty Notes") {
    @Previewable @State var notes: [ListingNote] = []
    @Previewable @State var inputText = ""

    NotesSection(
        notes: notes,
        inputText: $inputText,
        onSubmit: {
            let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let newNote = ListingNote(
                id: UUID().uuidString,
                listingId: "listing-1",
                content: trimmed,
                type: "general",
                createdBy: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            inputText = ""
        }
    )
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
    @Previewable @State var inputText = ""

    NotesSection(
        notes: notes,
        inputText: $inputText,
        onSubmit: {
            let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let newNote = ListingNote(
                id: UUID().uuidString,
                listingId: "listing-1",
                content: trimmed,
                type: "general",
                createdBy: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            inputText = ""
        }
    )
    .padding()
}
