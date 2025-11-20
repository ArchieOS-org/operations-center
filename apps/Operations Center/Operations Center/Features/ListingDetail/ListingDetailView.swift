//
//  ListingDetailView.swift
//  Operations Center
//
//  Listing Detail screen - THE INVERSE PULLEY
//  Physics: Swipe DOWN → Content moves down, Header pulls UP
//  Per TASK_MANAGEMENT_SPEC.md lines 338-375
//

import SwiftUI
import OperationsCenterKit

/// Listing Detail screen - see and claim activities within a listing
/// Per spec: "Purpose: See and claim Activities within a Listing"
/// Features: Pulley header, notes with scroll-to-recent, activities/tasks sections
struct ListingDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    /// Store is @Observable AND @State for projected value binding
    /// @State wrapper enables $store for Binding properties
    @State private var store: ListingDetailStore

    // MARK: - Scroll State

    /// Tracks which element is used for initial scroll positioning
    @State private var scrollTargetID: String?

    /// Prevents re-scrolling on data changes after initial load
    @State private var hasScrolledToInitialPosition = false

    /// Header scroll state: baseline and offset relative to that baseline
    @State private var headerScroll = HeaderScrollState()

    // MARK: - Layout Constants

    private enum HeaderMetrics {
        /// Total height of the header container
        static let height: CGFloat = 96
        /// Fraction of the header height used as top spacer so content slightly overlaps
        static let overlapFraction: CGFloat = 0.5
        /// Scroll distance (points) from baseline at which the header is fully compact
        static let collapseDistance: CGFloat = 80
    }

    // MARK: - Initialization

    init(
        listingId: String,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        taskRepository: TaskRepositoryClient,
        realtorRepository: RealtorRepositoryClient
    ) {
        _store = State(initialValue: ListingDetailStore(
            listingId: listingId,
            listingRepository: listingRepository,
            noteRepository: noteRepository,
            taskRepository: taskRepository,
            realtorRepository: realtorRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        // Capture state for visualEffect (avoid MainActor isolation warnings)
        let offset = headerScroll.relativeOffset

        ZStack(alignment: .top) {
            // The Pulley Header (fixed position, visual transform only)
            headerView
                .zIndex(1)
                .visualEffect { content, _ in
                    content
                        // Inverse: scroll down = header up
                        .offset(y: min(0, -offset))
                }

            // Main Scroll Content
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // Top spacer for partial header clearance (allow overlap)
                    Color.clear.frame(height: HeaderMetrics.height * HeaderMetrics.overlapFraction)

                    // Notes Section (rendered as list items, not a compound component)
                    notesListSection

                    // Marketing Activities Section
                    if !store.marketingActivities.isEmpty {
                        Section {
                            ForEach(store.marketingActivities) { activity in
                                activityCard(activity)
                            }
                        } header: {
                            sectionHeader(title: "Marketing Activities", count: store.marketingActivities.count)
                                .id("marketingActivitiesHeader")
                        }
                    }

                    // Admin Activities Section
                    if !store.adminActivities.isEmpty {
                        Section {
                            ForEach(store.adminActivities) { activity in
                                activityCard(activity)
                            }
                        } header: {
                            sectionHeader(title: "Admin Activities", count: store.adminActivities.count)
                        }
                    }

                    // Other Activities Section
                    if !store.otherActivities.isEmpty {
                        Section {
                            ForEach(store.otherActivities) { activity in
                                activityCard(activity)
                            }
                        } header: {
                            sectionHeader(title: "Other Activities", count: store.otherActivities.count)
                        }
                    }

                    // Uncategorized Activities Section
                    if !store.uncategorizedActivities.isEmpty {
                        Section {
                            ForEach(store.uncategorizedActivities) { activity in
                                activityCard(activity)
                            }
                        } header: {
                            sectionHeader(title: "Uncategorized", count: store.uncategorizedActivities.count)
                        }
                    }

                    // Bottom spacer to prevent last activity from being obscured by input bar
                    Color.clear.frame(height: 120)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollTargetID, anchor: .top)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newOffset in
                // Capture the baseline offset once we've scrolled to the initial position
                if hasScrolledToInitialPosition, headerScroll.baseline == nil {
                    headerScroll.baseline = newOffset
                }

                let baseline = headerScroll.baseline ?? 0
                // Scroll offset is now relative to the initial load position
                headerScroll.relativeOffset = newOffset - baseline
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                noteInputBar
            }
        }
        .navigationTitle(store.listing?.title ?? "Listing")
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.fetchListingData()
            await scrollToInitialPosition()
        }
        .loadingOverlay(store.isLoading && store.listing == nil)
        .errorAlert($store.errorMessage)
        .overlay(alignment: .bottom) {
            // Floating action bar when activity is expanded
            if let expandedId = store.expandedActivityId,
               let activity = findExpandedActivity(id: expandedId) {
                DSContextMenu(actions: buildActivityActions(for: activity))
                    .padding(.bottom, Spacing.lg)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedActivityId)
    }

    // MARK: - Subviews

    /// The Pulley Header - two states, crossfading based on scroll distance from initial position
    @ViewBuilder
    private var headerView: some View {
        let transition = headerTransitionProgress(for: headerScroll.relativeOffset)
        let title = store.listing?.title ?? "Listing"
        // Safe optional chaining: use realtor name, fallback to realtor ID, then nil
        let realtorName = store.realtor?.name ?? (store.listing?.realtorId)

        ZStack(alignment: .topLeading) {
            // Primary header (initial state) - larger, with background, overlaps notes
            ListingHeader(
                mode: .primary,
                title: title,
                realtorName: realtorName,
                onBack: { dismiss() }
            )
            .opacity(1 - transition)

            // Compact header (scrolled state) - smaller, no background
            ListingHeader(
                mode: .compact,
                title: title,
                realtorName: realtorName,
                onBack: { dismiss() }
            )
            .opacity(transition)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(
            Colors.surfacePrimary
                // Background only for primary state
                .opacity(1 - transition)
        )
        .frame(height: HeaderMetrics.height, alignment: .bottom)
    }

    /// Notes rendered as individual rows in the main scroll view
    @ViewBuilder
    private var notesListSection: some View {
        LazyVStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(sortedNotes) { note in
                NoteRowView(note: note)
                    .id(note.id)
                    .padding(.horizontal, Spacing.md)
            }
        }
        .padding(.top, Spacing.md)
    }

    /// Input bar for adding new notes
    @ViewBuilder
    private var noteInputBar: some View {
        NoteInputBar(
            text: $store.noteInputText,
            onSubmit: store.submitNote
        )
    }

    @ViewBuilder
    private func activityCard(_ activity: Activity) -> some View {
        if let listing = store.listing {
            ActivityCard(
                task: activity,
                listing: listing,
                isExpanded: store.expandedActivityId == activity.id,
                onTap: {
                    withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                        store.toggleExpansion(for: activity.id)
                    }
                }
            )
            .strikethrough(activity.completedAt != nil)
            .opacity(activity.completedAt != nil ? 0.6 : 1.0)
            .id(activity.id)
            .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Colors.surfacePrimary)
    }

    // MARK: - Helper Methods

    /// Notes sorted chronologically (oldest at top, newest at bottom)
    private var sortedNotes: [ListingNote] {
        store.notes.sorted { $0.createdAt < $1.createdAt }
    }

    /// Crossfade progress between primary and compact headers based on distance
    /// from the initial scroll position. 0 = fully primary, 1 = fully compact.
    private func headerTransitionProgress(for offset: CGFloat) -> Double {
        let distance = abs(offset)
        let raw = distance / HeaderMetrics.collapseDistance
        return Double(min(max(raw, 0), 1))
    }

    /// Scroll to the Marketing Activities header on initial load
    /// This positions the "Marketing Activities" section as the primary focal point
    private func scrollToInitialPosition() async {
        guard !hasScrolledToInitialPosition else { return }
        guard !store.marketingActivities.isEmpty else { return }

        // Small delay ensures layout is complete
        try? await Task.sleep(for: .milliseconds(100))

        // Scroll so that the Marketing Activities header becomes the reference point
        scrollTargetID = "marketingActivitiesHeader"

        hasScrolledToInitialPosition = true
    }

    private func findExpandedActivity(id: String) -> Activity? {
        store.activities.first(where: { $0.id == id })
    }

    private func buildActivityActions(for activity: Activity) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
            onClaim: {
                Task { await store.claimActivity(activity) }
            },
            onDelete: {
                Task { await store.deleteActivity(activity) }
            }
        )
    }
}

/// Local header scroll state: baseline offset and offset relative to that baseline
private struct HeaderScrollState {
    var baseline: CGFloat?
    var relativeOffset: CGFloat = 0
}

// MARK: - Supporting Views

/// Pure header view used by ListingDetailView; all state is supplied via arguments.
private struct ListingHeader: View {
    enum Mode {
        case primary
        case compact
    }

    let mode: Mode
    let title: String
    let realtorName: String?
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch mode {
            case .primary:
                primaryContent
            case .compact:
                compactContent
            }
        }
    }

    /// Large, on-load header: back arrow, big address, realtor line
    private var primaryContent: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(realtorName ?? "Realtor Name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    /// Compact header used when scrolled away from the initial position
    private var compactContent: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()
        }
    }
}

/// Simple note row renderer
private struct NoteRowView: View {
    let note: ListingNote

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Circle()
                .fill(avatarColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(initials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(note.createdByName ?? "Unknown")
                        .font(Typography.cardSubtitle.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(formatTime(note.createdAt))
                        .font(Typography.chipLabel)
                        .foregroundStyle(.tertiary)
                }

                Text(note.content)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var initials: String {
        guard let name = note.createdByName else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(name.prefix(2))
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo]
        let hash = (note.createdByName ?? "").hashValue
        return colors[abs(hash) % colors.count]
    }

    private func formatTime(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds/60))m ago" }
        if seconds < 86400 { return "\(Int(seconds/3600))h ago" }
        return "\(Int(seconds/86400))d ago"
    }
}

/// Input bar for adding notes - docked to bottom with safeAreaInset
private struct NoteInputBar: View {
    @Binding var text: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var isSubmitEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField("Add a note...", text: $text, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...4)
                .focused($isFocused)
                .padding(Spacing.sm)
                .background(Colors.surfaceTertiary)
                .cornerRadius(CornerRadius.md)
                .onKeyPress(.return, phases: .down) { keyPress in
                    if keyPress.modifiers.contains(.command) {
                        handleSubmit()
                        return .handled
                    }
                    return .ignored
                }

            if isSubmitEnabled {
                Button(action: handleSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Send note")
            }
        }
        .padding(Spacing.md)
        .animation(.snappy, value: isSubmitEnabled)
    }

    private func handleSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ListingDetailView(
            listingId: "listing_001",
            listingRepository: .preview,
            noteRepository: .preview,
            taskRepository: .preview,
            realtorRepository: .preview
        )
    }
}

