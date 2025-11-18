//
//  ListingCard.swift
//  OperationsCenterKit
//
//  Card for displaying listings with their associated tasks
//

import SwiftUI

/// Card for displaying listings (top-level property containers)
public struct ListingCard: View {
    // MARK: - Properties

    let listing: Listing
    let realtor: Realtor?
    let tasks: [Activity]
    let notes: [ListingNote]
    @Binding var noteInputText: String
    let isExpanded: Bool
    let onTap: () -> Void
    let onTaskTap: (Activity) -> Void
    let onSubmitNote: () -> Void

    // MARK: - Initialization

    public init(
        listing: Listing,
        realtor: Realtor?,
        tasks: [Activity],
        notes: [ListingNote],
        noteInputText: Binding<String>,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onTaskTap: @escaping (Activity) -> Void,
        onSubmitNote: @escaping () -> Void
    ) {
        self.listing = listing
        self.realtor = realtor
        self.tasks = tasks
        self.notes = notes
        self._noteInputText = noteInputText
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onTaskTap = onTaskTap
        self.onSubmitNote = onSubmitNote
    }

    // MARK: - Body

    public var body: some View {
        CardBase(
            tintColor: Colors.surfaceListingTinted,
            isExpanded: isExpanded,
            onTap: onTap
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                CardHeader(
                    title: listing.title,
                    subtitle: realtor?.name,
                    chips: buildChips(),
                    dueDate: listing.dueDate,
                    isExpanded: isExpanded
                )

                // Expanded content
                if isExpanded {
                    // Notes Section
                    NotesSection(
                        notes: notes,
                        inputText: $noteInputText,
                        onSubmit: onSubmitNote
                    )

                    // Listing Activities Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Activities")
                            .font(Typography.cardSubtitle)
                            .foregroundStyle(.secondary)

                        if tasks.isEmpty {
                            Text("No activities yet")
                                .font(Typography.body)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, Spacing.sm)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(tasks) { task in
                                    listingTaskRow(for: task)
                                }
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Listing type chip only
        if let listingType = listing.listingType {
            chips.append(.custom(
                text: listingType.rawValue,
                color: listingType.color
            ))
        }

        return chips
    }

    @ViewBuilder
    private func listingTaskRow(for task: Activity) -> some View {
        Button {
            onTaskTap(task)
        } label: {
            HStack(spacing: Spacing.sm) {
                // Task status indicator
                Circle()
                    .fill(statusColor(for: task.status))
                    .frame(width: 8, height: 8)

                // Task name
                Text(task.name)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Task category badge
                if let category = task.taskCategory {
                    Text(category.rawValue)
                        .font(Typography.chipLabel)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.sm)
            .background(Colors.surfaceTertiary)
            .cornerRadius(CornerRadius.sm)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(activityAccessibilityLabel(for: task))
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .open: return Colors.statusOpen
        case .claimed: return Colors.statusClaimed
        case .inProgress: return Colors.statusInProgress
        case .done: return Colors.statusCompleted
        case .failed: return Colors.statusFailed
        case .cancelled: return Colors.statusCancelled
        }
    }

    private func activityAccessibilityLabel(for task: Activity) -> String {
        let statusName = task.status.displayName
        if let category = task.taskCategory {
            return "\(task.name), \(statusName), \(category.rawValue)"
        } else {
            return "\(task.name), \(statusName), Uncategorized"
        }
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    @Previewable @State var notes: [ListingNote] = []
    @Previewable @State var noteInput = ""

    let listing = Listing(
        id: "listing-001",
        addressString: "123 Maple Street",
        status: "inbox",
        assignee: nil,
        realtorId: "realtor_001",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 0.0,
        type: "RESIDENTIAL",
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    ListingCard(
        listing: listing,
        realtor: .mock1,
        tasks: [],
        notes: notes,
        noteInputText: $noteInput,
        isExpanded: false,
        onTap: {},
        onTaskTap: { _ in },
        onSubmitNote: {
            let trimmed = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let newNote = ListingNote(
                id: UUID().uuidString,
                listingId: listing.id,
                content: trimmed,
                type: "general",
                createdBy: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            noteInput = ""
        }
    )
    .padding()
}

#Preview("Expanded with Tasks") {
    @Previewable @State var notes: [ListingNote] = [
        ListingNote(
            id: "note-1",
            listingId: "listing-001",
            content: "Follow up with agent about staging timeline",
            type: "general",
            createdBy: "Sarah Chen",
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-7200)
        ),
        ListingNote(
            id: "note-2",
            listingId: "listing-001",
            content: "Property needs deep cleaning before photos",
            type: "general",
            createdBy: "Mike Torres",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        )
    ]
    @Previewable @State var noteInput = ""

    let listing = Listing(
        id: "listing-001",
        addressString: "456 Oak Avenue",
        status: "inbox",
        assignee: nil,
        realtorId: "realtor_002",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 30.0,
        type: "LUXURY",
        createdAt: Date().addingTimeInterval(-5 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-1 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    let tasks = [
        Activity(
            id: "1",
            listingId: "listing-001",
            realtorId: "realtor_002",
            name: "Schedule professional photos",
            description: "Book photographer",
            taskCategory: nil,  // Uncategorized
            status: .open,
            priority: 1,
            visibilityGroup: .both,
            assignedStaffId: nil,
            dueDate: Date().addingTimeInterval(3 * 24 * 3600),
            claimedAt: nil,
            completedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        ),
        Activity(
            id: "2",
            listingId: "listing-001",
            realtorId: "realtor_002",
            name: "Deep clean interior",
            description: "Professional cleaning service",
            taskCategory: .admin,  // Admin category
            status: .claimed,
            priority: 2,
            visibilityGroup: .both,
            assignedStaffId: "Clean Team",
            dueDate: Date().addingTimeInterval(2 * 24 * 3600),
            claimedAt: Date(),
            completedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        ),
        Activity(
            id: "3",
            listingId: "listing-001",
            realtorId: "realtor_002",
            name: "Social media campaign",
            description: "Launch property on social platforms",
            taskCategory: .marketing,  // Marketing category
            status: .inProgress,
            priority: 3,
            visibilityGroup: .both,
            assignedStaffId: "Marketing Team",
            dueDate: Date().addingTimeInterval(5 * 24 * 3600),
            claimedAt: Date().addingTimeInterval(-1 * 24 * 3600),
            completedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            deletedBy: nil,
            inputs: nil,
            outputs: nil
        )
    ]

    ListingCard(
        listing: listing,
        realtor: .mock2,
        tasks: tasks,
        notes: notes,
        noteInputText: $noteInput,
        isExpanded: true,
        onTap: {},
        onTaskTap: { _ in },
        onSubmitNote: {
            let trimmed = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let newNote = ListingNote(
                id: UUID().uuidString,
                listingId: listing.id,
                content: trimmed,
                type: "general",
                createdBy: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            noteInput = ""
        }
    )
    .padding()
}

#Preview("Expanded No Tasks") {
    @Previewable @State var notes: [ListingNote] = [
        ListingNote(
            id: "note-1",
            listingId: "listing-002",
            content: "New listing - needs initial assessment",
            type: "general",
            createdBy: "Emma Rodriguez",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        )
    ]
    @Previewable @State var noteInput = ""

    let listing = Listing(
        id: "listing-002",
        addressString: "789 Pine Boulevard",
        status: "inbox",
        assignee: nil,
        realtorId: "realtor_003",
        dueDate: Date().addingTimeInterval(14 * 24 * 3600),
        progress: 0.0,
        type: "COMMERCIAL",
        createdAt: Date().addingTimeInterval(-1 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-1 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    ListingCard(
        listing: listing,
        realtor: .mock3,
        tasks: [],
        notes: notes,
        noteInputText: $noteInput,
        isExpanded: true,
        onTap: {},
        onTaskTap: { _ in },
        onSubmitNote: {
            let trimmed = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let newNote = ListingNote(
                id: UUID().uuidString,
                listingId: listing.id,
                content: trimmed,
                type: "general",
                createdBy: "Current User",
                createdAt: Date(),
                updatedAt: Date()
            )
            notes.append(newNote)
            noteInput = ""
        }
    )
    .padding()
}
