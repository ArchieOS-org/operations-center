import SwiftUI

/// Reusable detail screen header with Linear-inspired structure
///
/// Design Spec (from research):
/// - Three-row composition:
///   Row 1: Control bar (44pt) with Back | Edit + Overflow
///   Row 2: Large title (up to 2 lines)
///   Row 3: Metadata slot (for chips or other components)
/// - Total header height: 112pt (Spacing.navHeaderHeight)
/// - 24pt top padding below Dynamic Island (Spacing.navHeaderTop)
/// - 16pt horizontal padding (Spacing.screenEdge)
/// - Clean separation: One interaction per row
/// - Supports two modes: .primary (expanded) and .compact (scrolled)
///
/// Usage:
/// ```swift
/// DSDetailHeader(
///     mode: .primary,
///     title: "123 Main St,\nSan Francisco",
///     onBack: { dismiss() },
///     onEdit: { showEditSheet = true },
///     onOverflow: { showMenu = true }
/// ) {
///     DSListingMetaChipsRow(...)
/// }
/// ```
public struct DSDetailHeader<MetaContent: View>: View {
    // MARK: - Mode

    public enum Mode {
        /// Expanded header shown at the top (before scrolling)
        case primary
        /// Compact header shown when scrolled
        case compact
    }

    // MARK: - Properties

    public let mode: Mode
    public let title: String
    public let onBack: () -> Void
    public let onEdit: (() -> Void)?
    public let onOverflow: (() -> Void)?
    public let metaContent: MetaContent

    // MARK: - Initialization

    /// Create a detail header with toolbar, title, and metadata slot
    /// - Parameters:
    ///   - mode: Display mode (primary or compact)
    ///   - title: Large title text (up to 2 lines)
    ///   - onBack: Action for back button
    ///   - onEdit: Optional action for edit button
    ///   - onOverflow: Optional action for overflow menu button
    ///   - metaContent: ViewBuilder for metadata row (e.g., chips)
    public init(
        mode: Mode,
        title: String,
        onBack: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onOverflow: (() -> Void)? = nil,
        @ViewBuilder metaContent: () -> MetaContent
    ) {
        self.mode = mode
        self.title = title
        self.onBack = onBack
        self.onEdit = onEdit
        self.onOverflow = onOverflow
        self.metaContent = metaContent()
    }

    // MARK: - Body

    public var body: some View {
        switch mode {
        case .primary:
            primaryContent
        case .compact:
            compactContent
        }
    }

    // MARK: - Primary Mode (Expanded)

    @ViewBuilder
    private var primaryContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: Control Bar (Back | Edit + Overflow)
            controlBar
                .frame(height: 44)

            // Row 2: Large Title
            titleView
                .padding(.top, Spacing.sm) // 8pt spacing between control bar and title

            // Row 3: Metadata Slot
            metaContent
                .padding(.top, Spacing.md) // 12pt spacing between title and chips
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenEdge) // 16pt screen edge padding
    }

    // MARK: - Compact Mode (Scrolled)

    @ViewBuilder
    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: Control Bar (Back | Edit + Overflow)
            controlBar
                .frame(height: 44)

            // Row 2: Compact Title (smaller, no metadata)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .padding(.top, Spacing.sm) // 8pt spacing between control bar and title
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenEdge) // 16pt screen edge padding
    }

    // MARK: - Subviews

    /// Row 1: Control toolbar with back, edit, and overflow buttons
    @ViewBuilder
    private var controlBar: some View {
        HStack(spacing: Spacing.sm) { // 8pt gap between buttons
            // Left: Back button
            DSBackButton(action: onBack)

            Spacer()

            // Right: Edit and Overflow buttons (8pt gap between them)
            HStack(spacing: Spacing.sm) {
                if let onEdit = onEdit {
                    DSEditIconButton(action: onEdit)
                }

                if let onOverflow = onOverflow {
                    DSOverflowIconButton(action: onOverflow)
                }
            }
        }
    }

    /// Row 2: Large title text
    @ViewBuilder
    private var titleView: some View {
        Text(title)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
    }
}

// MARK: - Convenience Init (No Meta Content)

extension DSDetailHeader where MetaContent == EmptyView {
    /// Create a detail header without metadata content
    public init(
        mode: Mode,
        title: String,
        onBack: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onOverflow: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.title = title
        self.onBack = onBack
        self.onEdit = onEdit
        self.onOverflow = onOverflow
        self.metaContent = EmptyView()
    }
}

// MARK: - Preview

#Preview("Detail Header with Meta Content") {
    VStack(spacing: 32) {
        Text("Primary Mode")
            .font(.caption)
            .foregroundStyle(.secondary)

        // With all buttons and chips
        DSDetailHeader(
            mode: .primary,
            title: "123 Main Street,\nSan Francisco",
            onBack: {},
            onEdit: {},
            onOverflow: {}
        ) {
            HStack(spacing: Spacing.sm) {
                DSChip(agentName: "Sarah Chen", style: .agentTask)
                DSChip(date: Date().addingTimeInterval(86400 * 2)) // 2 days from now
            }
        }
        .padding(.vertical, Spacing.md)
        .background(Colors.surfacePrimary)

        Divider()

        Text("Compact Mode")
            .font(.caption)
            .foregroundStyle(.secondary)

        // Compact mode (no chips)
        DSDetailHeader(
            mode: .compact,
            title: "123 Main Street,\nSan Francisco",
            onBack: {},
            onEdit: {},
            onOverflow: {}
        ) {
            HStack(spacing: Spacing.sm) {
                DSChip(agentName: "Sarah Chen", style: .agentTask)
                DSChip(date: Date().addingTimeInterval(86400 * 2))
            }
        }
        .padding(.vertical, Spacing.md)
        .background(Colors.surfacePrimary)
    }
}

#Preview("Detail Header over colorful background") {
    ZStack {
        LinearGradient(
            colors: [.purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            DSDetailHeader(
                mode: .primary,
                title: "789 Maple Drive,\nChicago",
                onBack: {},
                onEdit: {},
                onOverflow: {}
            ) {
                HStack(spacing: Spacing.sm) {
                    DSChip(agentName: "John Doe", style: .agentTask)
                    DSChip(date: Date().addingTimeInterval(-86400)) // Yesterday (overdue)
                }
            }
            .padding(.vertical, Spacing.md)

            Spacer()
        }
    }
}
