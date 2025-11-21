import CoreGraphics

/// Avatar size constants for consistent sizing across the app
///
/// Design Philosophy:
/// - Semantic naming for context-specific avatar uses
/// - Pairs with CornerRadius.avatarList for perfect circles
///
/// Usage:
/// ```swift
/// Circle()
///     .frame(width: AvatarSizes.list, height: AvatarSizes.list)
///     .cornerRadius(CornerRadius.avatarList)
/// ```
public enum AvatarSizes {
    /// Avatar size for list rows and cards (16pt circle)
    public static let list: CGFloat = 16

    /// Avatar size for detail sheets and profile cards (32pt circle)
    public static let detail: CGFloat = 32
}
