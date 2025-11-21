import SwiftUI

/// Spacing and layout token system
///
/// Design Philosophy:
/// - 4pt base grid with Apple-style 8 / 16 / 32pt rhythm
/// - Generous white space for clarity
/// - Consistent vertical rhythm across all UI
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

    /// Vertical padding for empty state views
    public static let emptyStateVertical: CGFloat = 60

    /// Top padding for large navigation headers / titles
    ///
    /// Used to pull large titles comfortably below the status bar / Dynamic Island,
    /// while still feeling visually connected to the top edge.
    public static let navHeaderTop: CGFloat = 24

    /// Top padding for compact navigation headers / toolbars
    ///
    /// Used when the header has scrolled to a compact state.
    public static let navHeaderTopCompact: CGFloat = 12

    /// Vertical spacing between a primary header and the first content section
    ///
    /// Keeps content from crowding the header while staying connected.
    public static let contentTop: CGFloat = 16

    /// Standard vertical spacing between stacked content sections
    public static let sectionVertical: CGFloat = 16

    /// Height for large navigation headers in detail-style screens
    ///
    /// Aligned with large-title nav bars and provides room below the status bar / Dynamic Island.
    public static let navHeaderHeight: CGFloat = 112

    /// Fraction of the header height used as a top spacer so content can slightly overlap
    public static let navHeaderOverlapFraction: CGFloat = 0.5

    /// Scroll distance (points) from the baseline at which nav headers are fully compact
    public static let navHeaderCollapseDistance: CGFloat = 80

    /// Bottom spacer height used to keep scroll content clear of a docked input bar
    public static let bottomInputBarSpacer: CGFloat = 120
}

// MARK: - EdgeInsets Extensions

public extension EdgeInsets {
    /// Standard list row insets for card-style rows (vertical: 8, horizontal: 16)
    static let listCardInsets: EdgeInsets = EdgeInsets(
        top: Spacing.listRowVertical,
        leading: Spacing.screenEdge,
        bottom: Spacing.listRowVertical,
        trailing: Spacing.screenEdge
    )

    /// Standard list row insets for standard rows (vertical: 8, horizontal: 16)
    static let listRowInsets: EdgeInsets = EdgeInsets(
        top: Spacing.listRowVertical,
        leading: Spacing.listRowHorizontal,
        bottom: Spacing.listRowVertical,
        trailing: Spacing.listRowHorizontal
    )
}
