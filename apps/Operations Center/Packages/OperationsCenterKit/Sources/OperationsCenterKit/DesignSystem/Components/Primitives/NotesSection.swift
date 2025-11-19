//
//  NotesSection.swift
//  OperationsCenterKit
//
//  THE ELASTIC ACCORDION
//  - No inner ScrollView (Page handles scrolling)
//  - Default: Last 3 notes
//  - Interaction: Drag down or Tap top to expand
//  - Conflict Free: Requires .refreshable to be removed from parent
//

import SwiftUI

public struct NotesSection: View {
    let notes: [ListingNote]
    @Binding var inputText: String
    let onSubmit: () -> Void

    @FocusState private var isInputFocused: Bool
    @State private var isExpanded = false
    @State private var triggerHaptic = false

    // MARK: - Computed Props

    // Sort: Oldest (Top) -> Newest (Bottom)
    private var sortedNotes: [ListingNote] {
        notes.sorted { $0.createdAt < $1.createdAt }
    }

    // Slice: If collapsed, show only last 3. If expanded, show all.
    private var visibleNotes: [ListingNote] {
        guard !isExpanded else { return sortedNotes }
        return Array(sortedNotes.suffix(3))
    }

    private var hasHiddenNotes: Bool {
        notes.count > 3
    }

    // MARK: - Init

    public init(
        notes: [ListingNote],
        inputText: Binding<String>,
        onSubmit: @escaping () -> Void
    ) {
        self.notes = notes
        self._inputText = inputText
        self.onSubmit = onSubmit
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 1. The "Handle" / Expansion Trigger
            // Only visible if we have hidden history
            if hasHiddenNotes {
                ExpansionTrigger(isExpanded: isExpanded)
                    .onTapGesture { toggleExpansion() }
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onEnded { value in
                                if value.translation.height > 0 && !isExpanded {
                                    toggleExpansion() // Drag Down -> Expand
                                } else if value.translation.height < 0 && isExpanded {
                                    toggleExpansion() // Drag Up -> Collapse
                                }
                            }
                    )
                    .zIndex(1) // Ensure it sits above the animating list
            }

            // 2. The List
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(visibleNotes) { note in
                    NoteRow(note: note)
                        .id(note.id)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
            // When collapsed, add a top padding to account for the gradient/handle area
            .padding(.top, (hasHiddenNotes && !isExpanded) ? 0 : Spacing.md)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: visibleNotes.count)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)

            // 3. Input Section
            InputBar(
                text: $inputText,
                isFocused: $isInputFocused,
                onSubmit: handleSubmit
            )
        }
        // Haptic feedback on expansion toggle
        .sensoryFeedback(.selection, trigger: isExpanded)
        // Haptic feedback on new note
        .sensoryFeedback(.impact(weight: .light), trigger: triggerHaptic)
        .onChange(of: notes.count) { oldCount, newCount in
            if newCount > oldCount {
                triggerHaptic.toggle()
                // Optional: Auto-expand if they add a note?
                // Steve: No. Keep it minimal. Let them expand if they want context.
            }
        }
    }

    private func toggleExpansion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isExpanded.toggle()
        }
    }

    private func handleSubmit() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit()
        // Keep focus for rapid fire
    }
}

// MARK: - Subviews

private struct ExpansionTrigger: View {
    let isExpanded: Bool

    var body: some View {
        HStack {
            Spacer()
            // Subtle Handle Indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 32, height: 4)
            Spacer()
        }
        .padding(.vertical, 12)
        .background {
            if !isExpanded {
                // The "Fade" Mask when collapsed
                LinearGradient(
                    colors: [
                        Colors.surfacePrimary.opacity(0),
                        Colors.surfacePrimary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .padding(-20) // Bleed out
            }
        }
        .contentShape(Rectangle()) // Make the clear area tappable
    }
}

// MARK: - Input Bar (Unchanged)
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

// MARK: - Note Row (Unchanged)
private struct NoteRow: View {
    let note: ListingNote
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Circle()
                .fill(avatarColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(initials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(note.createdByName ?? "Unknown")
                        .font(Typography.cardSubtitle.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .alignmentGuide(.top) { d in d[.top] + 2 }

                    Text("·")
                        .foregroundStyle(.tertiary)
                        .alignmentGuide(.top) { d in d[.top] + 2 }

                    Text(formatTime(note.createdAt))
                        .font(Typography.chipLabel)
                        .foregroundStyle(.tertiary)
                        .alignmentGuide(.top) { d in d[.top] + 2 }
                }

                Text(note.content)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isHovering ? 0.8 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var initials: String {
        guard let name = note.createdByName else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(name.prefix(2))
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo]
        let hash = (note.createdByName ?? "").hashValue
        return colors[abs(hash) % colors.count]
    }

    private func formatTime(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds/60))m ago" }
        if seconds < 86400 { return "\(Int(seconds/3600))h ago" }
        return "\(Int(seconds/86400))d ago"
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
