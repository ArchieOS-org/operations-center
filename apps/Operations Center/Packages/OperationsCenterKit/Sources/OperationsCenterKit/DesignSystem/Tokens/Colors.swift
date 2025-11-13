import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Semantic color system with automatic dark mode support
public enum Colors {
    public static let primary = Color.accentColor
    public static let secondary = Color.secondary

    public static let background: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }()

    public static let cardBackground: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    public static let shadowLight = Color.black.opacity(0.05)
    public static let shadowMedium = Color.black.opacity(0.1)

    // MARK: - Card Accents

    /// Accent color for stray tasks (orphaned, untethered)
    public static let strayAccent = Color.orange

    /// Accent color for listing tasks (property-linked, has a home)
    public static let listingAccent = Color.blue

    // MARK: - Card Backgrounds

    /// Background for all cards - uses system color for automatic dark mode
    public static let cardSystemBackground: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    /// Subtle tint overlay for stray task cards (imperceptible but effective)
    public static let strayCardTint = Color.orange.opacity(0.03)

    /// Subtle tint overlay for listing task cards (imperceptible but effective)
    public static let listingCardTint = Color.blue.opacity(0.02)

    // MARK: - Actions

    /// Color for claim/primary actions
    public static let claimAction = Color.blue

    /// Color for destructive actions (delete)
    public static let deleteAction = Color.red

    /// Color for complete actions
    public static let completeAction = Color.green
}
