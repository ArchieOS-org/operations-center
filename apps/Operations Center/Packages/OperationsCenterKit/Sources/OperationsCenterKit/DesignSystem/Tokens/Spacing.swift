import SwiftUI

/// Spacing and layout token system
///
/// Design Philosophy:
/// - 8pt grid system (4, 8, 12, 16, 24, 32, 48...)
/// - Generous white space for clarity
/// - Consistent rhythm across all UI
///
/// Usage:
/// - padding(.horizontal, Spacing.screenEdge)
/// - VStack(spacing: Spacing.md)
/// - .frame(maxHeight, Spacing.maxContentHeight)
public enum Spacing {
    // MARK: - Base Spacing Scale

    /// Extra small spacing (4pt) - tight grouping
    public static let xs: CGFloat = 4

    /// Small spacing (8pt) - related elements
    public static let sm: CGFloat = 8

    /// Medium spacing (12pt) - section spacing
    public static let md: CGFloat = 12

    /// Large spacing (16pt) - distinct sections
    public static let lg: CGFloat = 16

    /// Extra large spacing (24pt) - major sections
    public static let xl: CGFloat = 24

    /// Extra extra large spacing (32pt) - screen sections
    public static let xxl: CGFloat = 32

    // MARK: - Semantic Layout Values

    /// Horizontal screen edge padding
    public static let screenEdge: CGFloat = 16

    /// Vertical padding for list rows
    public static let listRowVertical: CGFloat = 8

    /// Horizontal padding for list rows
    public static let listRowHorizontal: CGFloat = 16

    /// Maximum height for scrollable content sections (notes, activities)
    public static let maxContentHeight: CGFloat = 240
}
