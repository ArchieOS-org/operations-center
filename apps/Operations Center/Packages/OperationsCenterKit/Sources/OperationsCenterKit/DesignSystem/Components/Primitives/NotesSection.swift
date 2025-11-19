//
//  NotesSection.swift
//  OperationsCenterKit
//
//  GOLDEN MASTER
//  - Fixed: Avatar vertical alignment (pinned to leading edge)
//  - Fixed: Optical text alignment (cap-height correction)
//  - Fixed: Chronology (Oldest -> Newest)
//  - Fixed: Input scrolling behavior
//

import SwiftUI

/// Premium notes section with multi-line input and avatar-based rows
/// Clean text on parent surface, no backgrounds, fuzzy timestamps
public struct NotesSection: View {
    let notes: [ListingNote]
    @Binding var inputText: String
    let onSubmit: () -> Void

    @FocusState private var isInputFocused: Bool

    // SORTING: Oldest at Top -> Newest at Bottom (Standard timeline flow)
    private var sortedNotes: [ListingNote] {
        notes.sorted { $0.createdAt < $1.createdAt }
    }

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
        VStack(alignment: .leading, spacing: 0) {
            // Notes list
            if !notes.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        // CRITICAL FIX: alignment: .leading
                        // Prevents short notes from centering and shifting the avatar right
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(sortedNotes) { note in
                                NoteRow(note: note)
                                    .id(note.id)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading) // Force scroll content width
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: notes.count) { oldCount, newCount in
                        // Auto-scroll to the bottom (Newest)
                        if newCount > oldCount, let lastNote = sortedNotes.last {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
                                proxy.scrollTo(lastNote.id, anchor: .bottom)
                            }
                        }
                    }
                }
            } else {
                Spacer()
            }

            // Input section (Sits at bottom)
            InputBar(
                text: $inputText,
                isFocused: $isInputFocused,
                onSubmit: handleSubmit
            )
        }
    }

    private func handleSubmit() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit()
        isInputFocused = false
    }
}

// MARK: - Input Bar

private struct InputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    private var isSubmitEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField("Add a note...", text: $text, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...4)
                .focused(isFocused)
                .padding(Spacing.sm)
                .background(Colors.surfaceTertiary)
                .cornerRadius(CornerRadius.md)
                .onKeyPress(.return, phases: .down) { keyPress in
                    if keyPress.modifiers.contains(.command) {
                        onSubmit()
                        return .handled
                    }
                    return .ignored
                }

            // Button only appears when needed
            if isSubmitEnabled {
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Send note")
            }
        }
        .padding(Spacing.md)
        .animation(.snappy, value: isSubmitEnabled)
    }
}

// MARK: - Note Row

private struct NoteRow: View {
    let note: ListingNote
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Avatar (Anchor)
            Circle()
                .fill(avatarColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(initials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header
                HStack(spacing: Spacing.xs) {
                    Text(note.createdByName ?? "Unknown")
                        .font(Typography.cardSubtitle.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .offset(y: -2) // Optical alignment with 32pt avatar

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(formatTime(note.createdAt))
                        .font(Typography.chipLabel)
                        .foregroundStyle(.tertiary)
                        .offset(y: -2) // Optical alignment with 32pt avatar
                }

                // Body
                Text(note.content)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true) // Wrap text properly
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure row fills width
        .opacity(isHovering ? 0.8 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Helpers

    private var initials: String {
        guard let name = note.createdByName else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let last = components[1].prefix(1).uppercased()
            return first + last
        }
        return String(name.prefix(2).uppercased())
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo]
        let hash = (note.createdByName ?? "").hashValue
        return colors[abs(hash) % colors.count]
    }

    private func formatTime(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}

// MARK: - Previews

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
                type: .general,
                createdBy: "staff_current",
                createdByName: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            inputText = ""
        }
    )
    .padding()
    .background(Colors.surfacePrimary)
}

#Preview("With Notes") {
    @Previewable @State var notes: [ListingNote] = [
        ListingNote(
            id: "1",
            listingId: "listing-1",
            content: "Need staging by Friday",
            type: .general,
            createdBy: "staff_001",
            createdByName: "Mike Torres",
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-7200)
        ),
        ListingNote(
            id: "2",
            listingId: "listing-1",
            content: "Photos scheduled for Tuesday",
            type: .general,
            createdBy: "staff_002",
            createdByName: "Sarah Chen",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        ListingNote(
            id: "3",
            listingId: "listing-1",
            content: "Property showing went well. Buyer seems very interested. Following up tomorrow morning.",
            type: .general,
            createdBy: "staff_003",
            createdByName: "Alex Kim",
            createdAt: Date().addingTimeInterval(-1800),
            updatedAt: Date().addingTimeInterval(-1800)
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
                type: .general,
                createdBy: "staff_current",
                createdByName: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            inputText = ""
        }
    )
    .padding()
    .background(Colors.surfacePrimary)
}

#Preview("Long Content Stress Test") {
    @Previewable @State var inputText = ""
    @Previewable @State var notes: [ListingNote] = {
        let longContent = "This is a much longer note that spans multiple lines to test text wrapping and vertical spacing. The layout should remain clean and readable even with significant content."
        let names = ["Mike Torres", "Sarah Chen", "Alex Kim", "Jordan Lee"]
        var result: [ListingNote] = []
        for index in 1...12 {
            let note = ListingNote(
                id: "\(index)",
                listingId: "listing-1",
                content: index % 3 == 0 ? longContent : "Short note \(index)",
                type: .general,
                createdBy: "staff_\(index)",
                createdByName: names[index % 4],
                createdAt: Date().addingTimeInterval(Double(-index * 3600)),
                updatedAt: Date().addingTimeInterval(Double(-index * 3600))
            )
            result.append(note)
        }
        return result
    }()

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
                type: .general,
                createdBy: "staff_current",
                createdByName: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            inputText = ""
        }
    )
    .padding()
    .background(Colors.surfacePrimary)
}
