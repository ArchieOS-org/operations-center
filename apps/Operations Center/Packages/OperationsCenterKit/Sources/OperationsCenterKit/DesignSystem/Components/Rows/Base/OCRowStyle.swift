//
//  OCRowStyle.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Encapsulates default paddings and separator insets for rows
public struct OCRowStyle {
    public let horizontalPadding: CGFloat
    public let verticalPadding: CGFloat
    public let separatorInsets: EdgeInsets

    /// The default row style matching current list row insets
    public static let `default` = OCRowStyle(
        horizontalPadding: Spacing.listRowHorizontal,
        verticalPadding: Spacing.listRowVertical,
        separatorInsets: EdgeInsets(
            top: 0,
            leading: Spacing.listRowHorizontal,
            bottom: 0,
            trailing: 0
        )
    )

    /// Compact style with reduced padding
    public static let compact = OCRowStyle(
        horizontalPadding: Spacing.md,
        verticalPadding: Spacing.xs,
        separatorInsets: EdgeInsets(
            top: 0,
            leading: Spacing.md,
            bottom: 0,
            trailing: 0
        )
    )

    /// Spacious style with increased padding
    public static let spacious = OCRowStyle(
        horizontalPadding: Spacing.xl,
        verticalPadding: Spacing.md,
        separatorInsets: EdgeInsets(
            top: 0,
            leading: Spacing.xl,
            bottom: 0,
            trailing: 0
        )
    )

    public init(
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        separatorInsets: EdgeInsets
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.separatorInsets = separatorInsets
    }
}

// MARK: - Environment Key

private struct OCRowStyleKey: EnvironmentKey {
    static let defaultValue = OCRowStyle.default
}

public extension EnvironmentValues {
    var ocRowStyle: OCRowStyle {
        get { self[OCRowStyleKey.self] }
        set { self[OCRowStyleKey.self] = newValue }
    }
}

public extension View {
    /// Apply a row style to this view and its descendants
    func ocRowStyle(_ style: OCRowStyle) -> some View {
        environment(\.ocRowStyle, style)
    }
}