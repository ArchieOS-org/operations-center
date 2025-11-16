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
    let tasks: [Activity]
    let isExpanded: Bool
    let onTap: () -> Void
    let onTaskTap: (Activity) -> Void
    let onMove: () -> Void
    let onDelete: () -> Void

    @Binding var editableNotes: String

    // MARK: - Initialization

    public init(
        listing: Listing,
        tasks: [Activity],
        editableNotes: Binding<String>,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onTaskTap: @escaping (Activity) -> Void,
        onMove: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.listing = listing
        self.tasks = tasks
        self._editableNotes = editableNotes
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onTaskTap = onTaskTap
        self.onMove = onMove
        self.onDelete = onDelete
    }

    // MARK: - Body

    public var body: some View {
        CardBase(
            tintColor: Colors.listingCardTint,
            isExpanded: isExpanded,
            onTap: onTap
        ) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                CardHeader(
                    title: listing.title,
                    subtitle: agentName,
                    chips: buildChips(),
                    dueDate: listing.dueDate,
                    isExpanded: isExpanded
                )

                // Expanded content
                if isExpanded {
                    // Notes Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Notes")
                            .font(Typography.cardSubtitle)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $editableNotes)
                            .font(Typography.body)
                            .foregroundStyle(.primary)
                            .frame(minHeight: 80)
                            .padding(Spacing.sm)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .scrollContentBackground(.hidden)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))

                    // Listing Tasks Section
                    if !tasks.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Tasks")
                                .font(Typography.cardSubtitle)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 0) {
                                ForEach(tasks) { task in
                                    listingTaskRow(for: task)
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                    }

                    // Context Menu (Bottom Actions)
                    DSContextMenu(actions: [
                        DSContextAction(
                            title: "Move",
                            systemImage: "arrow.right.circle"
                        ) {
                            onMove()
                        },
                        DSContextAction(
                            title: "Delete",
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            onDelete()
                        }
                    ])
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                }
            }
        }
    }

    // MARK: - Helper Methods

    private var agentName: String? {
        listing.agentId
    }

    private func buildChips() -> [ChipData] {
        var chips: [ChipData] = []

        // Agent chip (if present)
        if let agentId = listing.agentId {
            chips.append(.agent(name: agentId, style: .listing))
        }

        // Type chip (if present)
        if let type = listing.type {
            chips.append(.custom(
                text: type,
                color: typeColor(for: type)
            ))
        }

        return chips
    }

    private func typeColor(for type: String) -> Color {
        switch type.uppercased() {
        case "RESIDENTIAL": return .blue
        case "COMMERCIAL": return .purple
        case "LUXURY": return .orange
        default: return .gray
        }
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

                // Task category badge (if needed)
                Text(task.taskCategory.rawValue)
                    .font(Typography.chipLabel)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.sm)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: Activity.TaskStatus) -> Color {
        switch status {
        case .open: return .gray
        case .claimed: return .orange
        case .inProgress: return .blue
        case .done: return .green
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    @Previewable @State var notes = ""

    let listing = Listing(
        id: "listing-001",
        addressString: "123 Maple Street",
        status: "inbox",
        assignee: nil,
        agentId: "Sarah Chen",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 0.0,
        type: "RESIDENTIAL",
        notes: "",
        createdAt: Date().addingTimeInterval(-2 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-2 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    ListingCard(
        listing: listing,
        tasks: [],
        editableNotes: $notes,
        isExpanded: false,
        onTap: {},
        onTaskTap: { _ in },
        onMove: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Expanded with Tasks") {
    @Previewable @State var notes =
        "Follow up with agent about staging timeline. Property needs deep cleaning before photos."

    let listing = Listing(
        id: "listing-001",
        addressString: "456 Oak Avenue",
        status: "inbox",
        assignee: nil,
        agentId: "Mike Torres",
        dueDate: Date().addingTimeInterval(7 * 24 * 3600),
        progress: 30.0,
        type: "LUXURY",
        notes: notes,
        createdAt: Date().addingTimeInterval(-5 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-1 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    let tasks = [
        Activity(
            id: "1",
            listingId: "listing-001",
            realtorId: "realtor-1",
            name: "Schedule professional photos",
            description: "Book photographer",
            taskCategory: .photo,
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
            realtorId: "realtor-1",
            name: "Deep clean interior",
            description: "Professional cleaning service",
            taskCategory: .admin,
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
            realtorId: "realtor-1",
            name: "Stage master bedroom",
            description: "Furniture and decor",
            taskCategory: .staging,
            status: .inProgress,
            priority: 3,
            visibilityGroup: .both,
            assignedStaffId: "Staging Co",
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
        tasks: tasks,
        editableNotes: $notes,
        isExpanded: true,
        onTap: {},
        onTaskTap: { _ in },
        onMove: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Expanded No Tasks") {
    @Previewable @State var notes = "New listing - needs initial assessment"

    let listing = Listing(
        id: "listing-002",
        addressString: "789 Pine Boulevard",
        status: "inbox",
        assignee: nil,
        agentId: "Emma Rodriguez",
        dueDate: Date().addingTimeInterval(14 * 24 * 3600),
        progress: 0.0,
        type: "COMMERCIAL",
        notes: notes,
        createdAt: Date().addingTimeInterval(-1 * 24 * 3600),
        updatedAt: Date().addingTimeInterval(-1 * 24 * 3600),
        completedAt: nil,
        deletedAt: nil
    )

    ListingCard(
        listing: listing,
        tasks: [],
        editableNotes: $notes,
        isExpanded: true,
        onTap: {},
        onTaskTap: { _ in },
        onMove: {},
        onDelete: {}
    )
    .padding()
}
