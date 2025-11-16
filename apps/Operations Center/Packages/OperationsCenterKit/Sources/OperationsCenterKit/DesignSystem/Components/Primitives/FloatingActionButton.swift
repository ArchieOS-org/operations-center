//
//  FloatingActionButton.swift
//  OperationsCenterKit
//
//  Floating action button for primary actions
//  Per TASK_MANAGEMENT_SPEC.md lines 451-464
//

import SwiftUI

/// Floating action button positioned at bottom right
///
/// Per TASK_MANAGEMENT_SPEC.md:
/// - "Default behavior: Opens new Task modal" (line 453)
/// - "On task list screens: Opens new Task inline at bottom of list" (line 456)
/// - "On Listing Screen: Adds Activity to current Listing" (line 459)
/// - "During creation: No action bar shown" (line 462)
public struct FloatingActionButton: View {
    // MARK: - Properties

    private let action: () -> Void
    private let systemImage: String
    private let accessibilityLabel: String

    // MARK: - Initialization

    public init(
        systemImage: String = "plus",
        accessibilityLabel: String = "Add",
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(FloatingActionButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Button Style

private struct FloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}

// MARK: - View Extension

public extension View {
    /// Adds a floating action button overlay to the view
    /// Positioned at bottom trailing with padding
    /// Slides down off-screen when hidden (context menu appears)
    ///
    /// - Parameters:
    ///   - systemImage: SF Symbol name (default: "plus")
    ///   - accessibilityLabel: VoiceOver label (default: "Add")
    ///   - isHidden: Whether to slide FAB off-screen (default: false)
    ///   - action: Action to perform when tapped
    func floatingActionButton(
        systemImage: String = "plus",
        accessibilityLabel: String = "Add",
        isHidden: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .bottomTrailing) {
            FloatingActionButton(
                systemImage: systemImage,
                accessibilityLabel: accessibilityLabel,
                action: action
            )
            .padding(Spacing.lg)
            .offset(y: isHidden ? 100 : 0)
            .opacity(isHidden ? 0 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.1), value: isHidden)
        }
    }
}

// MARK: - Previews

#Preview("Default Plus") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Text("Screen Content")
                .font(.title)
        }
    }
    .floatingActionButton {
    }
}

#Preview("Custom Icon") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Text("Listing Screen")
                .font(.title)
        }
    }
    .floatingActionButton(systemImage: "list.bullet") {
    }
}
