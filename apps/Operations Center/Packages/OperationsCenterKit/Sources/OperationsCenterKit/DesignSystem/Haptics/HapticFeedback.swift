//
//  HapticFeedback.swift
//  OperationsCenterKit
//
//  Haptic feedback system using SwiftUI's native SensoryFeedback
//  Clean, declarative, type-safe haptics for all interactions
//

import SwiftUI

// MARK: - Haptic Feedback View Extensions

extension View {
    /// Adds selection haptic feedback (for toggles, pickers, segmented controls)
    /// Attaches selection-style haptic feedback that fires when the provided trigger changes.
    /// - Parameters:
    ///   - trigger: A value whose change (compared by equality) causes the selection haptic to be emitted.
    /// - Returns: A view that emits a selection haptic each time `trigger` changes.
    public func selectionFeedback<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.selection, trigger: trigger)
    }

    /// Adds tap haptic feedback (for buttons, cards, standard interactions)
    /// Adds a medium-weight impact haptic that fires when the provided trigger value changes.
    /// - Parameter trigger: A value whose change will cause the medium impact haptic to fire.
    /// - Returns: A view that emits a medium impact haptic when `trigger` changes.
    public func tapFeedback(trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact(weight: .medium), trigger: trigger)
    }

    /// Adds light haptic feedback (for subtle interactions)
    /// Adds a light-impact haptic feedback to the view when the provided trigger changes.
    /// - Parameters:
    ///   - trigger: The value whose change causes a light-impact haptic to be emitted.
    /// - Returns: A view that emits a light-impact haptic when `trigger` changes.
    public func lightFeedback(trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact(weight: .light), trigger: trigger)
    }

    /// Adds heavy haptic feedback (for destructive or important actions)
    /// Attaches a heavy impact haptic feedback to the view that fires when the provided trigger changes.
    /// - Parameter trigger: A value whose changes (compared by `Equatable`) cause the heavy haptic to be emitted.
    /// - Returns: A view that emits a heavy impact haptic when `trigger` changes.
    public func heavyFeedback(trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact(weight: .heavy), trigger: trigger)
    }

    /// Adds result-based haptic feedback (success or error)
    /// Adds result-based haptic feedback driven by changes to `trigger`.
    /// - Parameters:
    ///   - trigger: The value to observe; changes to this value cause feedback to be evaluated.
    ///   - isSuccess: A closure that receives the updated `trigger` value and returns `true` when the update represents a successful result.
    /// - Returns: A view that emits a `.success` haptic when `isSuccess` returns `true` for the updated trigger value, or `.error` otherwise.
    public func resultFeedback<T>(
        trigger: T,
        isSuccess: @escaping (T) -> Bool
    ) -> some View where T: Equatable {
        self.sensoryFeedback(trigger: trigger) { _, newValue in
            isSuccess(newValue) ? .success : .error
        }
    }

    /// Adds conditional haptic feedback
    /// Attaches conditional haptic feedback to the view that fires when a change in `trigger` satisfies the given condition.
    /// - Parameters:
    ///   - trigger: The value to observe for changes; the closure receives the previous and new values when a change occurs.
    ///   - shouldFire: A closure that receives the previous and new `trigger` values and returns `true` when feedback should be emitted.
    ///   - feedback: The `SensoryFeedback` to emit when the condition is met. Defaults to a medium impact.
    /// - Returns: A view that emits the specified haptic feedback when `shouldFire` returns `true` for a change in `trigger`.
    public func conditionalFeedback<T: Equatable>(
        trigger: T,
        shouldFire: @escaping (T, T) -> Bool,
        feedback: SensoryFeedback = .impact(weight: .medium)
    ) -> some View {
        self.sensoryFeedback(feedback, trigger: trigger, condition: shouldFire)
    }
}

// MARK: - Haptic Trigger

/// Helper for triggering haptics based on state changes
/// Use when you need to fire a haptic without a specific value change
public struct HapticTrigger: Equatable {
    private let id = UUID()

    public init() {}

    /// Create a new `HapticTrigger` to programmatically fire haptic feedback.
    /// - Returns: A fresh `HapticTrigger` instance that can be used to trigger haptic feedback.
    public static func fire() -> HapticTrigger {
        HapticTrigger()
    }
}

// MARK: - Usage Examples

/*
 Example 1: Button Tap
 -------
 Button("Claim Task") {
     Task { await claimTask() }
 }
 .tapFeedback(trigger: claimCount)

 Example 2: Card Expansion
 -------
 CardView()
     .lightFeedback(trigger: isExpanded)

 Example 3: Toggle Selection
 -------
 Toggle("Notifications", isOn: $notificationsEnabled)
     .selectionFeedback(trigger: notificationsEnabled)

 Example 4: Destructive Action
 -------
 Button("Delete", role: .destructive) {
     deleteItem()
 }
 .heavyFeedback(trigger: deleteCount)

 Example 5: Success/Error Result
 -------
 SaveButton()
     .resultFeedback(trigger: saveResult) { result in
         if case .success = result { return true }
         return false
     }

 Example 6: Conditional Feedback (only on expand, not collapse)
 -------
 CardView()
     .conditionalFeedback(trigger: isExpanded) { old, new in
         !old && new  // Only fire when changing from false to true
     }

 Example 7: Manual Trigger
 -------
 @State private var hapticTrigger = HapticTrigger()

 Button("Action") {
     performAction()
     hapticTrigger = .fire()  // Trigger haptic
 }
 .tapFeedback(trigger: hapticTrigger)
 */