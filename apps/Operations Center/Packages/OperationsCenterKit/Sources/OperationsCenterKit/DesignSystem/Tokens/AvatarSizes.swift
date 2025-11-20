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
    /// Avatar size for list rows and cards (36pt circle, matches iOS-style list avatars)
    public static let list: CGFloat = 16
}
