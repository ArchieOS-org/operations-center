import SwiftUI

/// Icon size constants for consistent sizing across the app
///
/// Design Philosophy:
/// - Consistent sizing for icons across UI
/// - Semantic naming for context-specific uses
/// - SF Symbols scale correctly at these sizes
public enum IconSizes {
    // MARK: - Standard Icon Sizes

    /// Empty state icons (large, prominent)
    public static let emptyState: CGFloat = 60

    /// Toolbar and navigation icons
    public static let toolbar: CGFloat = 16

    /// Status indicator dots/circles
    public static let statusIndicator: CGFloat = 8

    /// Divider icons (between content sections)
    public static let divider: CGFloat = 20

    /// Standard inline icons (in text/buttons)
    public static let inline: CGFloat = 16

    /// Small icons (badges, chips)
    public static let small: CGFloat = 12

    /// Large icons (headers, prominent UI)
    public static let large: CGFloat = 24
}
