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
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    // System background (automatic dark mode)
                    Colors.cardSystemBackground

                    // Subtle tint overlay (imperceptible but effective)
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
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: isPressed)
        ._onButtonGesture { pressing in
            isPressed = pressing
        } perform: {}
    }

    // MARK: - Actions

    private func handleTap() {
        onTap()
    }
}

// MARK: - Preview

#Preview("Stray Card Base") {
    CardBase(
        tintColor: Colors.strayCardTint,
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
        tintColor: Colors.listingCardTint,
        isExpanded: false,
        onTap: {}
    ) {
        VStack(alignment: .leading, spacing: 8) {
            Text("123 Maple Street")
                .font(Typography.cardTitle)
            Text("This is a preview of the card base")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
