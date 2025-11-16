import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Semantic color system with automatic dark mode support
///
/// Design Philosophy:
/// - All colors backed by system colors for perfect light/dark adaptation
/// - Semantic naming describes role, not appearance
/// - No raw color literals - every color has meaning
/// - Sufficient contrast for WCAG AA compliance
public enum Colors {
    // MARK: - Surfaces

    /// Primary background (screen-level)
    public static let surfacePrimary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }()

    /// Secondary background (cards, elevated content)
    public static let surfaceSecondary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    /// Tertiary background (inputs, nested elements)
    public static let surfaceTertiary: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }()

    /// Subtle tinted background for listing cards
    public static let surfaceListingTinted: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBlue).opacity(0.04)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemBlue).opacity(0.04)
        #endif
    }()

    /// Subtle tinted background for agent task cards
    public static let surfaceAgentTaskTinted: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemOrange).opacity(0.04)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemOrange).opacity(0.04)
        #endif
    }()

    // MARK: - Accents

    /// Primary accent (interactive elements, links)
    public static let accentPrimary = Color.accentColor

    /// Listing-related accent
    public static let accentListing: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBlue)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemBlue)
        #endif
    }()

    /// Agent task accent
    public static let accentAgentTask: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemOrange)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemOrange)
        #endif
    }()

    // MARK: - Actions

    /// Positive action (complete, confirm)
    public static let actionPositive: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemGreen)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemGreen)
        #endif
    }()

    /// Destructive action (delete, cancel permanently)
    public static let actionDestructive: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemRed)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemRed)
        #endif
    }()

    // MARK: - Status Indicators

    /// Open/unassigned status
    public static let statusOpen: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemGray)
        #endif
    }()

    /// Claimed status
    public static let statusClaimed: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemOrange)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemOrange)
        #endif
    }()

    /// In progress status
    public static let statusInProgress: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBlue)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemBlue)
        #endif
    }()

    /// Completed status
    public static let statusCompleted: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemGreen)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemGreen)
        #endif
    }()

    /// Failed status
    public static let statusFailed: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemRed)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemRed)
        #endif
    }()

    /// Cancelled status
    public static let statusCancelled = Color.secondary

    // MARK: - Listing Type Badges

    /// Residential listing type
    public static let badgeResidential: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemBlue)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemBlue)
        #endif
    }()

    /// Commercial listing type
    public static let badgeCommercial: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemPurple)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemPurple)
        #endif
    }()

    /// Luxury listing type
    public static let badgeLuxury: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemOrange)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemOrange)
        #endif
    }()

    /// Default listing type (fallback)
    public static let badgeDefault: Color = {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemGray)
        #endif
    }()
}
