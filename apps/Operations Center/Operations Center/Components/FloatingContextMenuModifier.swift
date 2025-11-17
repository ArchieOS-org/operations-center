//
//  FloatingContextMenuModifier.swift
//  Operations Center
//
//  Reusable modifier for floating context menus
//  Eliminates duplication across MyTasksView, AllTasksView, TeamView, etc.
//

import SwiftUI

/// View modifier that displays a floating context menu at the bottom of the screen
/// Used when task cards are expanded to show available actions
struct FloatingContextMenuModifier: ViewModifier {
    let actions: [DSContextAction]
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isVisible {
                    DSContextMenu(actions: actions)
                        .padding(.bottom, Spacing.lg)
                        .padding(.horizontal, Spacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
    }
}

extension View {
    /// Displays a floating context menu at the bottom when visible
    func floatingContextMenu(isVisible: Bool, actions: [DSContextAction]) -> some View {
        modifier(FloatingContextMenuModifier(actions: actions, isVisible: isVisible))
    }
}
