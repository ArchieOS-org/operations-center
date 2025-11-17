import SwiftUI

/// Unified empty state component
///
/// Design Philosophy:
/// - One consistent empty state across the app
/// - Large icon, clear message, optional action
/// - Semantic colors from design system
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

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: IconSizes.emptyState))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Empty state")

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title2)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.bordered)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Spacing.emptyStateVertical)
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
