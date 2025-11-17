import SwiftUI

/// Unified error state component
///
/// Design Philosophy:
/// - Consistent error display across the app
/// - Clear error message with optional retry action
/// - Uses semantic colors from design system
///
/// Usage:
/// ```swift
/// DSErrorState(
///     title: "Error loading tasks",
///     message: "Please try again",
///     retryAction: { await store.refresh() }
/// )
/// ```
public struct DSErrorState: View {
    private let title: String
    private let message: String
    private let retryAction: (() -> Void)?

    public init(
        title: String = "Error",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: IconSizes.emptyState))
                .foregroundStyle(Colors.actionDestructive)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.emptyStateVertical)
        .listRowSeparator(.hidden)
    }
}

#Preview("Error with Retry") {
    List {
        DSErrorState(
            title: "Error loading tasks",
            message: "We couldn't load your tasks. Please try again.",
            retryAction: { print("Retry") }
        )
    }
    .listStyle(.plain)
}

#Preview("Error without Retry") {
    List {
        DSErrorState(
            title: "No connection",
            message: "Check your internet connection and relaunch the app."
        )
    }
    .listStyle(.plain)
}
