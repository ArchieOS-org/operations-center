import SwiftUI

/// Typography hierarchy using Dynamic Type with semantic font styles
/// All fonts scale automatically with user's system text size preferences
///
/// Design Philosophy:
/// - Use system text styles (.headline, .body, etc.) for automatic Dynamic Type support
/// - Apply weight modifiers for hierarchy while preserving scalability
/// - Avoid fixed sizes - they break accessibility and user control
public enum Typography {
    // MARK: - Screen Hierarchy

    /// Large title for major screen headers
    public static let largeTitle = Font.largeTitle.weight(.bold)

    /// Primary title (main screen sections)
    public static let title = Font.title.weight(.bold)

    /// Secondary title (subsections)
    public static let title2 = Font.title2.weight(.semibold)

    /// Tertiary title (smaller sections)
    public static let title3 = Font.title3.weight(.semibold)

    // MARK: - Content Hierarchy

    /// Card titles, primary interactive labels
    /// Based on .headline for optimal Dynamic Type scaling
    public static let cardTitle = Font.headline.weight(.semibold)

    /// Card subtitles, secondary information
    /// Based on .subheadline for legibility at all sizes
    public static let cardSubtitle = Font.subheadline

    /// Body text, primary content
    public static let body = Font.body

    /// Metadata, timestamps, supplementary info
    /// Based on .caption for compact display with scaling
    public static let cardMeta = Font.caption

    /// Small labels, badges, chips
    /// Based on .caption2 - smallest readable size with Dynamic Type
    public static let chipLabel = Font.caption2.weight(.medium)

    // MARK: - Specialty

    /// Callouts, emphasized body text
    public static let callout = Font.callout

    /// Footnotes, legal text
    public static let footnote = Font.footnote
}
