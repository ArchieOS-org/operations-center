import SwiftUI

/// Typography hierarchy using San Francisco font system
public enum Typography {
    public static let largeTitle = Font.largeTitle.weight(.bold)
    public static let title1 = Font.title.weight(.bold)
    public static let title2 = Font.title2.weight(.semibold)
    public static let title3 = Font.title3.weight(.semibold)
    public static let headline = Font.headline
    public static let body = Font.body
    public static let callout = Font.callout
    public static let subheadline = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption1 = Font.caption
    public static let caption2 = Font.caption2

    // MARK: - Card Typography

    /// Task card title
    public static let cardTitle = Font.system(size: 17, weight: .semibold)

    /// Task card subtitle (property address)
    public static let cardSubtitle = Font.system(size: 15, weight: .regular)

    /// Card metadata (due dates, timestamps)
    public static let cardMeta = Font.system(size: 13, weight: .regular)

    /// Chip label (agent names, badges)
    public static let chipLabel = Font.system(size: 12, weight: .medium)
}
