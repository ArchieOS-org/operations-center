//
//  OCRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Expansion style for a row
public enum OCRowExpansionStyle {
    case none
    case inline
}

/// Generic row primitive for white-on-white lists
public struct OCRow<Content: View, ExpandedContent: View, Accessory: View>: View {
    @Environment(\.ocRowStyle) private var style

    private let content: Content
    private let expandedContent: ExpandedContent?
    private let accessory: Accessory?
    private let expansionStyle: OCRowExpansionStyle
    private let isExpanded: Bool
    private let onTap: (() -> Void)?

    public init(
        expansionStyle: OCRowExpansionStyle = .none,
        isExpanded: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder expandedContent: () -> ExpandedContent,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.expansionStyle = expansionStyle
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.content = content()
        self.expandedContent = expandedContent()
        self.accessory = accessory()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row content
            HStack(spacing: Spacing.md) {
                content

                if let accessory {
                    Spacer(minLength: 0)
                    accessory
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }

            // Expanded content (if applicable)
            if expansionStyle == .inline, isExpanded, let expandedContent {
                expandedContent
                    .padding(.horizontal, style.horizontalPadding)
                    .padding(.bottom, style.verticalPadding)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .background(Colors.surfacePrimary)
        .animation(Animations.standard, value: isExpanded)
    }
}

// MARK: - Convenience Initializers

extension OCRow where ExpandedContent == EmptyView {
    /// Initialize without expanded content
    public init(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.expansionStyle = .none
        self.isExpanded = false
        self.onTap = onTap
        self.content = content()
        self.expandedContent = nil
        self.accessory = accessory()
    }
}

extension OCRow where Accessory == EmptyView {
    /// Initialize without accessory
    public init(
        expansionStyle: OCRowExpansionStyle = .none,
        isExpanded: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.expansionStyle = expansionStyle
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.content = content()
        self.expandedContent = expandedContent()
        self.accessory = nil
    }
}

extension OCRow where ExpandedContent == EmptyView, Accessory == EmptyView {
    /// Initialize with only content
    public init(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.expansionStyle = .none
        self.isExpanded = false
        self.onTap = onTap
        self.content = content()
        self.expandedContent = nil
        self.accessory = nil
    }
}