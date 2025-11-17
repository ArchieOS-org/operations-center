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
/// ```
public struct DSEmptyState: View {
    private let icon: String
    private let title: String
    private let message: String
    private let action: (() -> Void)?
    private let actionTitle: String?

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: IconSizes.emptyState))
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title2)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.emptyStateVertical)
        .listRowSeparator(.hidden)
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
            actionTitle: "Create Task",
            action: { print("Create task") }
        )
    }
    .listStyle(.plain)
}
