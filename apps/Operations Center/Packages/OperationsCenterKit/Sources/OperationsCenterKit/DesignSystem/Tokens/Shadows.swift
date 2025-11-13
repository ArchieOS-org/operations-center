import SwiftUI

/// Shadow system for elevation and depth
/// Uses dual-layer shadows for realistic depth (Apple's latest pattern)
public enum Shadows {
    // MARK: - Card Shadows (Dual-Layer System)

    /// Primary depth shadow for cards
    public static func cardPrimaryShadow(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.08)
    }

    /// Secondary edge definition shadow for cards
    public static func cardSecondaryShadow(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.black.opacity(0.15)
            : Color.black.opacity(0.04)
    }

    // MARK: - Shadow Parameters

    /// Primary shadow radius
    public static let cardPrimaryRadius: CGFloat = 12

    /// Primary shadow Y offset
    public static let cardPrimaryOffset: CGFloat = 6

    /// Secondary shadow radius
    public static let cardSecondaryRadius: CGFloat = 2

    /// Secondary shadow Y offset
    public static let cardSecondaryOffset: CGFloat = 2
}
