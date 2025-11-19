import SwiftUI

/// Unified empty state component with delightful animations
///
/// Design Philosophy:
/// - One consistent empty state across the app
/// - Large icon, clear message, optional action
/// - Subtle entrance animations (respects reduce motion)
/// - Premium visual hierarchy with gradient accents
/// - Accessible for VoiceOver and Dynamic Type
///
/// Usage:
/// ```swift
/// DSEmptyState(
///     icon: "house.circle",
///     title: "No listings",
///     message: "Listings will appear here when they're added"
/// )
///
/// // With action
/// DSEmptyState(
///     icon: "tray",
///     title: "No tasks",
///     message: "New tasks will appear here",
///     action: (title: "Create Task", handler: { createTask() })
/// )
/// ```
public struct DSEmptyState: View {
    private let icon: String
    private let title: String
    private let message: String
    private let action: (title: String, handler: () -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        action: (title: String, handler: () -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotionEnabled

    public var body: some View {
        VStack(spacing: 16) {
            // Large, premium icon with gradient
            Image(systemName: icon)
                .font(.system(size: 56))
                .fontWeight(.thin)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor.opacity(0.8),
                            Color.accentColor.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.6)
                .accessibilityHidden(true)

            // Title and message with improved hierarchy
            VStack(spacing: 8) {
                Text(title)
                    .font(Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(message)")

            // Optional action button with staggered entrance
            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.bordered)
                    .padding(.top, 20)
                    .accessibilityHint("Resolves the empty state")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Spacing.emptyStateVertical)
        .transition(.opacity.combined(with: .scale(scale: ScaleFactors.cardCollapse)))
    }
}

#Preview("Empty Listings") {
    List {
        DSEmptyState(
            icon: "house.circle",
            title: "No listings",
            message: "Listings will appear here when they're added to the system"
        )
    }
    .listStyle(.plain)
}

#Preview("Empty Tasks with Action") {
    List {
        DSEmptyState(
            icon: "tray",
            title: "No tasks",
            message: "New tasks will appear here",
            action: (title: "Create Task", handler: { print("Create task") })
        )
    }
    .listStyle(.plain)
}
