//
//  NotesSection.swift
//  OperationsCenterKit
//
//  Notes list with always-ready input field
//

import SwiftUI

/// Section displaying notes with an always-visible input field
/// Zero modes - type, hit return, note appears
public struct NotesSection: View {
    // MARK: - Properties

    let notes: [ListingNote]
    let onAddNote: (String) -> Void

    @State private var newNoteText = ""
    @FocusState private var isInputFocused: Bool
    @State private var lastNoteIdToScroll: String?

    // MARK: - Initialization

    public init(
        notes: [ListingNote],
        onAddNote: @escaping (String) -> Void
    ) {
        self.notes = notes
        self.onAddNote = onAddNote
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section title
            Text("Notes")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)

            // Input field - always visible at top
            TextField("Add a note...", text: $newNoteText, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...3)
                .padding(Spacing.sm)
                .background(Colors.textFieldBackground)
                .cornerRadius(CornerRadius.sm)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onChange(of: newNoteText) { newValue in
                    guard isInputFocused else { return }
                    guard newValue.last == "\n" else { return }

                    // Remove the newline before submitting
                    newNoteText.removeLast()
                    submitNote()
                }

            // Notes list
            if !notes.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: Spacing.sm) {
                            ForEach(notes) { note in
                                NoteRow(note: note)
                                    .id(note.id)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .task {
                        // First render - scroll to bottom if needed
                        lastNoteIdToScroll = notes.last?.id
                    }
                    .onChange(of: notes.count) { _ in
                        // Someone added or removed a note - remember id
                        lastNoteIdToScroll = notes.last?.id
                    }
                    .onChange(of: lastNoteIdToScroll) { id in
                        guard let id else { return }
                        // Defer to next runloop so views are laid out
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
    }

    // MARK: - Helper Methods

    private func submitNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        onAddNote(trimmed)
        newNoteText = ""

        // Keep focus for rapid note-taking
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
