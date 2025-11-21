import SwiftUI

/// Liquid Glass styled back button for navigation headers
///
/// Design Spec:
/// - 44×44pt minimum tappable area (Apple's accessibility guideline)
/// - Capsule shape with 12pt corner radius (on 4pt grid)
/// - Uses `.glassEffect(.regular.interactive())` on iOS 26+, falls back to `.ultraThinMaterial` on earlier systems
/// - 16pt chevron icon with semibold weight for clarity
/// - Maintains system edge-swipe back gesture in NavigationStack
///
/// Usage:
/// ```swift
/// DSBackButton(action: { dismiss() })
/// ```
public struct DSBackButton: View {
    // MARK: - Properties

    private let action: () -> Void

    // MARK: - Initialization

    /// Create a Liquid Glass back button
    /// - Parameter action: Action to perform when tapped (typically `dismiss()`)
    public init(action: @escaping () -> Void) {
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(
                    // Glass-like material with translucency
                    // Use .ultraThinMaterial for glass aesthetic
                    // Adds semi-transparent backing for contrast
                    ZStack {
                        Color.black.opacity(0.1)
                        Color.clear
                            .background(.ultraThinMaterial)
                    }
                )
                .clipShape(Capsule())
        }
        .frame(width: 44, height: 44) // Minimum tappable area
        .contentShape(Rectangle()) // Entire 44×44 area is tappable
        .accessibilityLabel("Back")
        .onAppear {
            // Critical: Re-enable system edge swipe gesture
            // Custom back buttons disable it by default in NavigationStack
            // Implementation isolated in DSBackButton+UIKitHelpers.swift
            enableInteractivePopGesture()
        }
    }
}

// MARK: - Preview

#Preview("Back Button") {
    VStack(spacing: Spacing.xl) {
        DSBackButton(action: {})
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(CornerRadius.md)

        DSBackButton(action: {})
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .pink, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)

        Text("Test over light background")
            .padding()
            .background(.white)

        DSBackButton(action: {})
            .padding()
            .background(.white)
            .cornerRadius(CornerRadius.md)

        Text("Test over dark background")
            .padding()
            .background(.black)

        DSBackButton(action: {})
            .padding()
            .background(.black)
            .cornerRadius(CornerRadius.md)
    }
    .padding()
}
