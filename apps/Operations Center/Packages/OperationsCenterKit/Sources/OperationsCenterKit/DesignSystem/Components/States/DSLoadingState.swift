import SwiftUI

/// Unified loading state component
///
/// Design Philosophy:
/// - Consistent loading overlay across the app
/// - Optional message for context
/// - Non-intrusive, centered display
///
/// Usage:
/// ```swift
/// List { }
///     .loadingOverlay(store.isLoading)
///
/// // Or directly:
/// DSLoadingState(message: "Loading tasks...")
/// ```
public struct DSLoadingState: View {
    private let message: String?

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()

            if let message {
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowSeparator(.hidden)
    }
}

// MARK: - View Extension

public extension View {
    /// Displays a centered loading overlay with an optional message over the view when enabled.
    /// - Parameters:
    ///   - isLoading: Whether the loading overlay is shown.
    ///   - message: An optional message displayed beneath the spinner.
    /// - Returns: A view that overlays the original content with `DSLoadingState(message:)` if `isLoading` is true, otherwise the original content.
    func loadingOverlay(_ isLoading: Bool, message: String? = nil) -> some View {
        overlay {
            if isLoading {
                DSLoadingState(message: message)
            }
        }
    }
}

#Preview("Loading with Message") {
    List {
        Text("Content below")
    }
    .listStyle(.plain)
    .loadingOverlay(true, message: "Loading tasks...")
}

#Preview("Loading without Message") {
    List {
        Text("Content below")
    }
    .listStyle(.plain)
    .loadingOverlay(true)
}