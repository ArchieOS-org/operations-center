import SwiftUI

/// Animation presets for consistent timing and feel
///
/// Design Philosophy:
/// - Physics-based spring animations (response + dampingFraction)
/// - Consistent motion across UI
/// - Premium, responsive feel with proper bounce
///
/// Research-driven animation timing from iOS HIG and Context7:
/// - Card interactions: response 0.3s, damping 0.68-0.7 (responsive, alive)
/// - Quick interactions: response 0.25s, damping 0.7 (snappy)
/// - Smooth transitions: response 0.4s, damping 0.8 (calm, deliberate)
///
/// Semantic Animation System:
/// Base animations are defined once, semantic names alias them for clarity.
/// This ensures synchronized values while maintaining intent-revealing APIs.
public enum Animations {
    // MARK: - Base Animations

    /// Medium-paced spring with responsive bounce (0.3s response, 0.68 damping)
    /// Feels premium and alive - use for card expansion, state changes
    private static let springMedium = Animation.spring(response: 0.3, dampingFraction: 0.68)

    /// Fast spring with snappy bounce (0.25s response, 0.7 damping)
    /// Quick feedback - use for button presses, toggles
    private static let springFast = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Smooth spring with gentle bounce (0.4s response, 0.8 damping)
    /// Calm transitions - use for navigation, modal presentation
    private static let springSmooth = Animation.spring(response: 0.4, dampingFraction: 0.8)

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
