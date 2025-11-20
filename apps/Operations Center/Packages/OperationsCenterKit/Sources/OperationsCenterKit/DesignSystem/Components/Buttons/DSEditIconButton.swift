import SwiftUI

/// Liquid Glass styled Edit icon button for navigation headers
///
/// Design Spec (from research):
/// - 44×44pt minimum tappable area (Apple accessibility standard)
/// - 18pt SF Symbol icon, regular weight
/// - Circular glass button with 12pt corner radius (on 4pt grid)
/// - `.regularMaterial` with subtle border for premium feel
/// - Light opacity change on press (0.8), no scale animation
///
/// Usage:
/// ```swift
/// DSEditIconButton(action: { showEditSheet = true })
/// ```
public struct DSEditIconButton: View {
    // MARK: - Properties

    private let action: () -> Void

    // MARK: - Initialization

    /// Create a Liquid Glass edit button
    /// - Parameter action: Action to perform when tapped
    public init(action: @escaping () -> Void) {
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(
                    // Minimal glass circular button
                    ZStack {
                        Color.clear
                            .background(.regularMaterial)
                        Color.black.opacity(0.05) // Subtle tint
                    }
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .frame(width: 44, height: 44) // Hit area = visual area for circular buttons
        .contentShape(Circle())
        .buttonStyle(GlassButtonStyle())
        .accessibilityLabel("Edit")
        .accessibilityHint("Double-tap to edit this listing")
    }
}

/// Custom button style for glass icon buttons
/// Light opacity on press (0.8), no scale animation for premium feel
private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Preview

#Preview("Edit Button") {
    VStack(spacing: Spacing.xl) {
        DSEditIconButton(action: {})
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(CornerRadius.md)

        DSEditIconButton(action: {})
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .pink, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)

        Text("Over light background")
            .padding()
            .background(.white)

        DSEditIconButton(action: {})
            .padding()
            .background(.white)
            .cornerRadius(CornerRadius.md)

        Text("Over dark background")
            .padding()
            .background(.black)

        DSEditIconButton(action: {})
            .padding()
            .background(.black)
            .cornerRadius(CornerRadius.md)
    }
    .padding()
}
