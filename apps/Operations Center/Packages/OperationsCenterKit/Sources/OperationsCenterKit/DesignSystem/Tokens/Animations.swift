import SwiftUI

/// Animation presets for consistent timing and feel
///
/// Design Philosophy:
/// - Modern spring API (duration + bounce)
/// - Consistent motion across UI
/// - Subtle but responsive feel
public enum Animations {
    /// Standard spring animation for card expansion (bouncy feel)
    public static let cardExpansion = Animation.spring(duration: 0.3, bounce: 0.1)

    /// Smooth card expansion without bounce
    public static let cardExpansionSmooth = Animation.spring(duration: 0.4, bounce: 0.0)

    /// Quick spring for subtle interactions
    public static let quick = Animation.spring(duration: 0.2, bounce: 0.3)

    /// Standard spring for general use
    public static let standard = Animation.spring(duration: 0.3, bounce: 0.1)

    /// Button press spring
    public static let buttonPress = Animation.spring(duration: 0.2, bounce: 0.3)
}
