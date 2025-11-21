import Foundation

/// Corner radius system for consistent rounding
public enum CornerRadius {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20

    /// Standard card corner radius
    public static let card: CGFloat = md

    /// Avatar circle radius (half of AvatarSizes.list for perfect circle)
    public static let avatarList: CGFloat = 18

    /// Bottom sheet corner radius (top corners only)
    public static let sheet: CGFloat = xl
}
