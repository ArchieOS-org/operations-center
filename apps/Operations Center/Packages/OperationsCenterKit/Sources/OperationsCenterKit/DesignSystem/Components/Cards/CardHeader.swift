//
//  CardHeader.swift
//  OperationsCenterKit
//
//  Card header with title, subtitle, and embedded chips
//  Used by both StrayTaskCard and ListingTaskCard
//

import SwiftUI

/// Card header displaying title, subtitle, and metadata chips
struct CardHeader: View {
    // MARK: - Properties

    let title: String
    let subtitle: String?
    let chips: [ChipData]

    // MARK: - Initialization

    init(title: String, subtitle: String? = nil, chips: [ChipData]) {
        self.title = title
        self.subtitle = subtitle
        self.chips = chips
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
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
            .agent(name: "Mike Torres", style: .listing),
            .dueDate(Date().addingTimeInterval(7 * 24 * 3600)), // Future
            .custom(text: "MARKETING", color: .purple)
        ]
    )
    .padding()
}
