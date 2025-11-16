//
//  OCListScaffold.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Shared scaffold for list-based screens
/// Wraps List or ScrollView contents and hosts shared bottom overlays
public struct OCListScaffold<Content: View, BottomOverlay: View>: View {
    @ViewBuilder private let content: Content
    @ViewBuilder private let bottomOverlay: BottomOverlay
    private let onRefresh: (() async -> Void)?

    public init(
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomOverlay: () -> BottomOverlay
    ) {
        self.onRefresh = onRefresh
        self.content = content()
        self.bottomOverlay = bottomOverlay()
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main list content
            List {
                content
            }
            .listStyle(.plain)
            .refreshable {
                if let onRefresh {
                    await onRefresh()
                }
            }
            .disabled(onRefresh == nil)

            // Bottom overlay (FAB, context menu, team toggle, etc.)
            bottomOverlay
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.lg)
        }
    }
}

// MARK: - Convenience Initializers

extension OCListScaffold where BottomOverlay == EmptyView {
    /// Initialize without bottom overlay
    public init(
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onRefresh = onRefresh
        self.content = content()
        self.bottomOverlay = EmptyView()
    }
}

// MARK: - ScrollView Variant

/// ScrollView-based scaffold for custom scroll content
public struct OCScrollScaffold<Content: View, BottomOverlay: View>: View {
    @ViewBuilder private let content: Content
    @ViewBuilder private let bottomOverlay: BottomOverlay
    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let onRefresh: (() async -> Void)?

    public init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomOverlay: () -> BottomOverlay
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.onRefresh = onRefresh
        self.content = content()
        self.bottomOverlay = bottomOverlay()
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main scroll content
            ScrollView(axes, showsIndicators: showsIndicators) {
                content
            }
            .refreshable {
                if let onRefresh {
                    await onRefresh()
                }
            }
            .disabled(onRefresh == nil)

            // Bottom overlay
            bottomOverlay
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.lg)
        }
    }
}

// MARK: - ScrollView Convenience Initializer

extension OCScrollScaffold where BottomOverlay == EmptyView {
    /// Initialize without bottom overlay
    public init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.onRefresh = onRefresh
        self.content = content()
        self.bottomOverlay = EmptyView()
    }
}