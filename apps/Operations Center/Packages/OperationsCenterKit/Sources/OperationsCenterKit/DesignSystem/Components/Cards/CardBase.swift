//
//  CardBase.swift
//  OperationsCenterKit
//
//  Shared foundation for StrayTaskCard and ListingTaskCard
//  Contains the 80% common structure: shadow, corner radius, tap behavior
//

import SwiftUI

/// Base card component providing shared structure for all task cards
/// Not used directly - extended by StrayTaskCard and ListingTaskCard
struct CardBase<Content: View>: View {
    // MARK: - Configuration

    let accentColor: Color
    let backgroundColor: Color
    let hasBorder: Bool
    let isExpanded: Bool
    let onTap: () -> Void

    @ViewBuilder let content: Content

    // MARK: - Initialization

    init(
        accentColor: Color,
        backgroundColor: Color,
        hasBorder: Bool,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.hasBorder = hasBorder
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 3pt accent bar on left edge
                accentBar

                // Card content
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(backgroundColor)
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(
                        hasBorder ? Colors.cardBorder : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Shadows.cardShadow,
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var accentBar: some View {
        Rectangle()
            .fill(accentColor)
            .frame(width: 3)
    }
}

// MARK: - Preview

#Preview("Stray Card Base") {
    CardBase(
        accentColor: Colors.strayAccent,
        backgroundColor: Colors.strayCardBackground,
        hasBorder: false,
        isExpanded: false,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Stray Task")
                .font(Typography.cardTitle)
            Text("This is a preview of the card base")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}

#Preview("Listing Card Base") {
    CardBase(
        accentColor: Colors.listingAccent,
        backgroundColor: Colors.listingCardBackground,
        hasBorder: true,
        isExpanded: false,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: 8) {
            Text("123 Maple Street")
                .font(Typography.cardTitle)
            Text("This is a preview of the card base with border")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
