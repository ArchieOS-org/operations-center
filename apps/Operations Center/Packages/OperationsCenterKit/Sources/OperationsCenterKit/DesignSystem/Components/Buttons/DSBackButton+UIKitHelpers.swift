import SwiftUI

// MARK: - Internal UIKit Helpers
//
// This file isolates UIKit interop code from the pure SwiftUI design system.
// Only used for edge cases where SwiftUI doesn't provide an API.

extension DSBackButton {
    /// Re-enables the interactive pop gesture (swipe from left edge to go back)
    ///
    /// **Why this exists:**
    /// NavigationStack disables the swipe-back gesture when using custom back buttons.
    /// Users expect this gesture, so we need to manually re-enable it via UIKit.
    ///
    /// **Warning:** This is a UIKit hack. It's isolated here to keep the main component pure SwiftUI.
    /// If Apple provides a SwiftUI API for this, delete this file and update DSBackButton.
    internal func enableInteractivePopGesture() {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let navigationController = windowScene.windows.first?.rootViewController as? UINavigationController
        else { return }

        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = nil
        #endif
    }
}
