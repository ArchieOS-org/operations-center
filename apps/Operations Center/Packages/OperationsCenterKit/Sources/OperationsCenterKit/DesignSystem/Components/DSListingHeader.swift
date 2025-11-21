import SwiftUI

/// Reusable navigation header for listing detail screens
///
/// Design Philosophy:
/// - Two modes: `.primary` (large header at top) and `.compact` (smaller header when scrolled)
/// - Liquid Glass aesthetic for the back button
/// - Consistent spacing using design system tokens
/// - Supports Dynamic Type and accessibility
///
/// Usage:
/// ```swift
/// DSListingHeader(
///     mode: .primary,
///     title: "123 Main St,\nSan Francisco",
///     realtorName: "John Doe",
///     listingType: .residential,
///     onBack: { dismiss() }
/// )
/// ```
public struct DSListingHeader: View {
    // MARK: - Mode

    public enum Mode {
        /// Large header shown at the top of the screen (before scrolling)
        case primary
        /// Compact header shown when content has scrolled
        case compact
    }

    // MARK: - Properties

    public let mode: Mode
    public let title: String
    public let realtorName: String?
    public let listingType: ListingType?
    public let onBack: () -> Void

    // MARK: - Initialization

    /// Create a listing header
    /// - Parameters:
    ///   - mode: Display mode (primary or compact)
    ///   - title: Address or listing title (up to 2 lines)
    ///   - realtorName: Realtor name (optional, shown only in primary mode)
    ///   - listingType: Listing type chip (optional, shown only in primary mode)
    ///   - onBack: Action to perform when back button is tapped
    public init(
        mode: Mode,
        title: String,
        realtorName: String? = nil,
        listingType: ListingType? = nil,
        onBack: @escaping () -> Void
    ) {
        self.mode = mode
        self.title = title
        self.realtorName = realtorName
        self.listingType = listingType
        self.onBack = onBack
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .topLeading) {
            switch mode {
            case .primary:
                primaryContent
            case .compact:
                compactContent
            }
        }
    }

    // MARK: - Primary Mode (Large Header)

    /// Large, on-load header: back arrow, big address, realtor line, listing type chip
    private var primaryContent: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            // Liquid Glass back button
            DSBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                Text(realtorName ?? "Realtor Name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Listing type chip
                if let listingType = listingType {
                    DSChip(text: listingType.rawValue, color: listingType.color)
                }
            }

            Spacer()
        }
    }

    // MARK: - Compact Mode (Scrolled Header)

    /// Compact header used when scrolled away from the initial position
    private var compactContent: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            // Liquid Glass back button (same component, same size)
            DSBackButton(action: onBack)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Primary Header") {
    VStack(spacing: 32) {
        DSListingHeader(
            mode: .primary,
            title: "123 Main Street,\nSan Francisco",
            realtorName: "John Doe",
            listingType: .residential,
            onBack: {}
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.md)
        .background(Colors.surfacePrimary)

        DSListingHeader(
            mode: .primary,
            title: "456 Oak Avenue,\nLos Angeles",
            realtorName: "Jane Smith",
            listingType: .commercial,
            onBack: {}
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.md)
        .background(Colors.surfacePrimary)
    }
}

#Preview("Compact Header") {
    VStack(spacing: 32) {
        DSListingHeader(
            mode: .compact,
            title: "123 Main Street,\nSan Francisco",
            realtorName: "John Doe",
            listingType: .residential,
            onBack: {}
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.sm)
        .background(Colors.surfacePrimary)

        DSListingHeader(
            mode: .compact,
            title: "456 Oak Avenue,\nLos Angeles",
            realtorName: "Jane Smith",
            listingType: .commercial,
            onBack: {}
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.sm)
        .background(Colors.surfacePrimary)
    }
}

#Preview("Mode Comparison") {
    VStack(spacing: 32) {
        Text("Primary Mode")
            .font(.caption)
            .foregroundStyle(.secondary)

        DSListingHeader(
            mode: .primary,
            title: "123 Main Street,\nSan Francisco",
            realtorName: "John Doe",
            listingType: .residential,
            onBack: {}
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.md)
        .background(Colors.surfacePrimary)

        Divider()

        Text("Compact Mode")
            .font(.caption)
            .foregroundStyle(.secondary)

        DSListingHeader(
            mode: .compact,
            title: "123 Main Street,\nSan Francisco",
            realtorName: "John Doe",
            listingType: .residential,
            onBack: {}
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.sm)
        .background(Colors.surfacePrimary)
    }
    .padding()
}
