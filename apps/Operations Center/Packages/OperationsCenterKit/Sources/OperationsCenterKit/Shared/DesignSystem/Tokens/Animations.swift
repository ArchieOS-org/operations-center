import SwiftUI

/// Animation presets for consistent timing and feel
public enum Animations {
    /// Standard spring animation for card expansion
    public static let cardExpansion = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Quick spring for subtle interactions
    public static let quick = Animation.spring(response: 0.2, dampingFraction: 0.8)

    /// Standard spring for general use
    public static let standard = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
