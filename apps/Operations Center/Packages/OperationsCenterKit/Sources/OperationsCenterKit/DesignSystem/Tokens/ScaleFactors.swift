import SwiftUI

/// Scale factor presets for consistent sizing transformations
///
/// Design Philosophy:
/// - Standardized scale values across the app
/// - Semantic naming for different interaction states
/// - Avoids hardcoded magic numbers in animations
public enum ScaleFactors {
    // MARK: - Interactive States

    /// Subtle shrink effect for card collapse/press (0.95)
    /// Used in: transitions, pressed states, collapsed cards
    public static let cardCollapse: CGFloat = 0.95

    /// Button press down scale (0.96)
    /// Creates tactile feedback without being too dramatic
    public static let buttonPress: CGFloat = 0.96

    /// Gentle expand for emphasis (1.05)
    /// Subtle grow effect for highlighting
    public static let gentleExpand: CGFloat = 1.05

    /// No transform (1.0) - neutral state
    public static let identity: CGFloat = 1.0
}
