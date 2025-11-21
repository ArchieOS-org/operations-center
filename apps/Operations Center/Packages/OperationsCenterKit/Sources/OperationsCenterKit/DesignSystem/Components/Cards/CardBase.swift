//
//  CardBase.swift
//  OperationsCenterKit
//
//  Shared foundation for TaskCard and ActivityCard
//  Modern implementation: dual-layer shadows, spring animations, system colors
//

import SwiftUI

/// Base card component providing shared structure for all task cards
/// Not used directly - extended by TaskCard and ActivityCard
struct CardBase<Content: View>: View {
    // MARK: - Configuration

    let tintColor: Color
    let isExpanded: Bool
    let onTap: () -> Void

    @ViewBuilder let content: Content

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(
        tintColor: Color,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.tintColor = tintColor
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // System background (automatic dark mode)
                Colors.surfaceSecondary

                // Subtle tint overlay
                tintColor
            }
        )
        .cornerRadius(CornerRadius.card)
        // Dual-layer shadow system for realistic depth
        .shadow(
            color: Shadows.cardSecondaryShadow(colorScheme),
            radius: Shadows.cardSecondaryRadius,
            x: 0,
            y: Shadows.cardSecondaryOffset
        )
        .shadow(
            color: Shadows.cardPrimaryShadow(colorScheme),
            radius: Shadows.cardPrimaryRadius,
            x: 0,
            y: Shadows.cardPrimaryOffset
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            handleTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sensoryFeedback(.selection, trigger: isExpanded)
    }

    // MARK: - Actions

    private func handleTap() {
        onTap()
    }
}

// MARK: - Preview

#Preview("Agent Task Card Base") {
    CardBase(
        tintColor: Colors.surfaceAgentTaskTinted,
        isExpanded: false,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: Spacing.sm) {
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
        tintColor: Colors.surfaceListingTinted,
        isExpanded: false,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("123 Maple Street")
                .font(Typography.cardTitle)
            Text("This is a preview of the card base")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
