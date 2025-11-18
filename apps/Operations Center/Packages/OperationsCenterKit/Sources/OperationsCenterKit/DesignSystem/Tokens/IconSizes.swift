import CoreGraphics

/// Icon size constants for consistent sizing across the app
///
/// Design Philosophy:
/// - Consistent sizing for icons across UI
/// - Semantic naming for context-specific uses
/// - SF Symbols scale correctly at these sizes
///
/// Accessibility:
/// - These sizes are base values for standard (100%) content size
/// - For dynamic type support, consider using `Image.scaleEffect()` or
///   applying a scale factor based on `@Environment(\.sizeCategory)`
/// - Example: `Image(systemName: "icon")
///     .font(.system(size: IconSizes.inline))
///     .scaleEffect(accessibilityScaleFactor)`
///
/// Note: `toolbar` and `inline` share the same value (16pt) but represent
/// different semantic contexts. `inline` is the general-purpose size for
/// icons within text/buttons, while `toolbar` specifically refers to
/// navigation bar and toolbar contexts. They may diverge in future design
/// iterations, so both constants are maintained for semantic clarity.
public enum IconSizes {
    // MARK: - Standard Icon Sizes

    /// Small icons (badges, chips)
    public static let small: CGFloat = 12

    /// Status indicator dots/circles
    public static let statusIndicator: CGFloat = 8

    /// Standard inline icons (in text/buttons)
    /// Also used for toolbar and navigation icons
    public static let inline: CGFloat = 16

    /// Toolbar and navigation icons
    /// Note: Currently shares value with `inline` (16pt) but maintained
    /// for semantic distinction in navigation/toolbar contexts
    public static let toolbar: CGFloat = 16

    /// Divider icons (between content sections)
    public static let divider: CGFloat = 20

    /// Large icons (headers, prominent UI)
    public static let large: CGFloat = 24

    /// Medium icons (moderate prominence, cards, lists)
    public static let medium: CGFloat = 32

    /// Extra large icons (featured content, hero sections)
    public static let extraLarge: CGFloat = 40

    /// Extra extra large icons (high emphasis, landing pages)
    public static let extraExtraLarge: CGFloat = 48

    /// Empty state icons (large, prominent)
    public static let emptyState: CGFloat = 60

    // MARK: - Accessibility Helpers

    /// Calculate accessibility-aware icon size based on content size category
    ///
    /// - Parameters:
    ///   - baseSize: The base icon size from this enum
    ///   - scaleFactor: Optional scale factor (defaults to 1.0)
    /// - Returns: Scaled size appropriate for accessibility settings
    ///
    /// Example usage:
    /// ```swift
    /// let iconSize = IconSizes.scaledSize(
    ///     baseSize: .inline,
    ///     scaleFactor: sizeCategory.scaleFactor
    /// )
    /// ```
    public static func scaledSize(baseSize: CGFloat, scaleFactor: CGFloat = 1.0) -> CGFloat {
        return baseSize * scaleFactor
    }
}
