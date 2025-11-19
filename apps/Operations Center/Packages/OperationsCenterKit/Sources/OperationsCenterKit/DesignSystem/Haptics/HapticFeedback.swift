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
    /// Use when: User changes a value in a multi-option control
    public func selectionFeedback<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.selection, trigger: trigger)
    }

    /// Adds tap haptic feedback (for buttons, cards, standard interactions)
    /// Use when: User taps a button or interactive element
    public func tapFeedback(trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact(weight: .medium), trigger: trigger)
    }

    /// Adds light haptic feedback (for subtle interactions)
    /// Use when: Card expansion, minor state changes, incremental actions
    public func lightFeedback(trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact(weight: .light), trigger: trigger)
    }

    /// Adds heavy haptic feedback (for destructive or important actions)
    /// Use when: Delete confirmation, major state transitions, errors
    public func heavyFeedback(trigger: some Equatable) -> some View {
        self.sensoryFeedback(.impact(weight: .heavy), trigger: trigger)
    }

    /// Adds result-based haptic feedback (success or error)
    /// Use when: Operation completes with success/failure outcome
    public func resultFeedback<T>(
        trigger: T,
        isSuccess: @escaping (T) -> Bool
    ) -> some View where T: Equatable {
        self.sensoryFeedback(trigger: trigger) { _, newValue in
            isSuccess(newValue) ? .success : .error
        }
    }

    /// Adds conditional haptic feedback
    /// Use when: Haptic should only fire under certain conditions
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
