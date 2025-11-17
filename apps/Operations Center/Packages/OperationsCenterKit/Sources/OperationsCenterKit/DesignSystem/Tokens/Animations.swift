import SwiftUI

/// Animation presets for consistent timing and feel
///
/// Design Philosophy:
/// - Modern spring API (duration + bounce)
/// - Consistent motion across UI
/// - Subtle but responsive feel
///
/// Semantic Animation System:
/// Base animations are defined once, semantic names alias them for clarity.
/// This ensures synchronized values while maintaining intent-revealing APIs.
public enum Animations {
    // MARK: - Base Animations

    /// Medium-paced spring with subtle bounce (0.3s, 0.1 bounce)
    private static let springMedium = Animation.spring(duration: 0.3, bounce: 0.1)

    /// Fast spring with moderate bounce (0.2s, 0.3 bounce)
    private static let springFast = Animation.spring(duration: 0.2, bounce: 0.3)

    /// Smooth spring without bounce (0.4s, 0.0 bounce)
    private static let springSmooth = Animation.spring(duration: 0.4, bounce: 0.0)

    // MARK: - Semantic Aliases

    /// Standard spring animation for card expansion (bouncy feel)
    public static let cardExpansion = springMedium

    /// Standard spring for general use
    public static let standard = springMedium

    /// Quick spring for subtle interactions
    public static let quick = springFast

    /// Button press spring
    public static let buttonPress = springFast

    /// Smooth card expansion without bounce
    public static let cardExpansionSmooth = springSmooth
}
