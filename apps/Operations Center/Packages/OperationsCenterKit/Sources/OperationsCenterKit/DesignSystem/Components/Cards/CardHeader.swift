//
//  CardHeader.swift
//  OperationsCenterKit
//
//  Card header with title, subtitle, and embedded chips
//  Used by both TaskCard and ActivityCard
//

import SwiftUI

/// Card header displaying title, subtitle, metadata chips, and due date
struct CardHeader: View {
    // MARK: - Properties

    let title: String
    let subtitle: String?
    let chips: [ChipData]
    let dueDate: Date?
    let isExpanded: Bool

    // MARK: - Initialization

    init(
        title: String,
        subtitle: String? = nil,
        chips: [ChipData],
        dueDate: Date? = nil,
        isExpanded: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.chips = chips
        self.dueDate = dueDate
        self.isExpanded = isExpanded
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title and date
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(Typography.cardTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    // Subtitle (if present)
                    if let subtitle {
                        Text(subtitle)
                            .font(Typography.cardSubtitle)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Due date (right side, format changes with state)
                if let dueDate {
                    dueDateView(for: dueDate)
                }
            }

            // Chips
            if !chips.isEmpty {
                HStack(spacing: 6) {
                    ForEach(chips) { chip in
                        chipView(for: chip)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func dueDateView(for date: Date) -> some View {
        ZStack(alignment: .trailing) {
            // Collapsed format: "MM-dd"
            Text(date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                .font(Typography.chipLabel)
                .foregroundStyle(.tertiary)
                .opacity(isExpanded ? 0 : 1)

            // Expanded format: "Month dd, yyyy"
            Text(date, format: .dateTime.month(.wide).day().year())
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
                .opacity(isExpanded ? 1 : 0)
        }
    }

    @ViewBuilder
    private func chipView(for chip: ChipData) -> some View {
        switch chip {
        case .agent(let name, let style):
            DSChip(agentName: name, style: style)
        case .dueDate(let date):
            DSChip(date: date)
        case .custom(let text, let color):
            DSChip(text: text, color: color)
        }
    }
}

// MARK: - Chip Data Model

enum ChipData: Identifiable {
    case agent(name: String, style: CardStyle)
    case dueDate(Date)
    case custom(text: String, color: Color)

    var id: String {
        switch self {
        case .agent(let name, _):
            return "agent-\(name)"
        case .dueDate(let date):
            return "date-\(date.timeIntervalSince1970)"
        case .custom(let text, let color):
            // Include color description to ensure uniqueness
            return "custom-\(text)-\(color.description)"
        }
    }
}

// MARK: - Preview

#Preview("Stray Task Header") {
    CardHeader(
        title: "Update CRM with Q4 contacts",
        subtitle: nil,
        chips: [
            .agent(name: "Sarah Chen", style: .stray),
            .dueDate(Date().addingTimeInterval(-2 * 24 * 3600)) // Overdue
        ]
    )
    .padding()
}

#Preview("Listing Task Header") {
    CardHeader(
        title: "Pre-listing prep",
        subtitle: "123 Maple Street",
        chips: [
            .agent(name: "Mike Torres", style: .activity),
            .dueDate(Date().addingTimeInterval(7 * 24 * 3600)), // Future
            .custom(text: "MARKETING", color: .purple)
        ]
    )
    .padding()
}
