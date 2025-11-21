import SwiftUI

/// Data model for listing metadata detail sheet
public struct ListingMetaDetail {
    public let agent: ListingAgentMeta
    public let slackMessage: SlackMessage?
    public let createdDate: Date
    public let channelId: String?

    public init(
        agent: ListingAgentMeta,
        slackMessage: SlackMessage?,
        createdDate: Date,
        channelId: String?
    ) {
        self.agent = agent
        self.slackMessage = slackMessage
        self.createdDate = createdDate
        self.channelId = channelId
    }
}

/// Reusable metadata detail sheet for listing headers
///
/// Design Spec (from research):
/// - Bottom sheet with .regularMaterial background, dark tint
/// - 60% screen height (or use presentationDetents(.fraction(0.6)))
/// - 20pt corner radius at top (5 × 4pt grid units)
/// - Structure:
///   1. Agent card (avatar + name + role)
///   2. Timeline section (Slack message + created date)
///   3. Contact info (email + phone, tappable links)
///   4. Action button ("Open Slack Channel")
/// - Drag to dismiss, standard iOS sheet behavior
/// - Accessibility: VoiceOver labels, Dynamic Type support
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showDetailSheet) {
///     DSListingMetaDetailSheet(
///         detail: ListingMetaDetail(
///             agent: realtor.meta,
///             slackMessage: message,
///             createdDate: listing.createdAt,
///             channelId: message?.channelId
///         ),
///         onOpenSlackChannel: { /* Open Slack app */ }
///     )
///     .presentationDetents([.fraction(0.6)])
///     .presentationDragIndicator(.visible)
/// }
/// ```
public struct DSListingMetaDetailSheet: View {
    // MARK: - Properties

    public let detail: ListingMetaDetail
    public let onOpenSlackChannel: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Create a listing metadata detail sheet
    /// - Parameters:
    ///   - detail: Metadata to display
    ///   - onOpenSlackChannel: Optional action to open Slack channel
    public init(
        detail: ListingMetaDetail,
        onOpenSlackChannel: (() -> Void)? = nil
    ) {
        self.detail = detail
        self.onOpenSlackChannel = onOpenSlackChannel
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) { // 16pt between sections
                // Agent Card
                agentCard

                // Timeline Section
                timelineSection

                // Contact Info
                contactInfoSection

                // Action Button
                if let onOpenSlackChannel = onOpenSlackChannel, detail.channelId != nil {
                    actionButton(action: onOpenSlackChannel)
                }
            }
            .padding(.horizontal, Spacing.lg) // 16pt horizontal padding
            .padding(.top, Spacing.md) // 12pt top padding below drag indicator
            .padding(.bottom, Spacing.lg) // 16pt bottom padding
        }
        .background(Color(.systemBackground)) // Use system background for proper light/dark mode
        .presentationCornerRadius(CornerRadius.sheet) // Bottom sheet corner radius
    }

    // MARK: - Subviews

    /// Agent card with avatar, name, and optional role
    @ViewBuilder
    private var agentCard: some View {
        HStack(spacing: Spacing.md) { // 12pt gap between avatar and text
            // Avatar placeholder (uses AvatarSizes.detail token)
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: AvatarSizes.detail, height: AvatarSizes.detail)
                .overlay {
                    Text(agentInitials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                }

            VStack(alignment: .leading, spacing: Spacing.xs) { // Use Spacing.xs (4pt)
                Text(detail.agent.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Listing Agent") // Role - could be dynamic in future
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(detail.agent.name), Listing Agent")
    }

    /// Timeline section with Slack message and created date
    @ViewBuilder
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) { // 12pt gap between items
            // Slack message (if available)
            if let message = detail.slackMessage {
                VStack(alignment: .leading, spacing: Spacing.xs + 2) { // 6pt (4 + 2)
                    Text("Message that created this")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Message snippet: \(message.text), sent at \(formatTimestamp(message.timestamp))")
            }

            // Created date
            VStack(alignment: .leading, spacing: Spacing.xs + 2) { // 6pt (4 + 2)
                Text("Created")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(formatDate(detail.createdDate))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Created on \(formatDate(detail.createdDate))")
        }
    }

    /// Contact info section with email and phone links
    @ViewBuilder
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) { // 12pt gap between items
            // Email link
            if let email = detail.agent.email {
                Link(destination: URL(string: "mailto:\(email)")!) {
                    HStack(spacing: Spacing.md) { // 12pt gap between icon and text
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .frame(width: IconSizes.toolbar) // Fixed width for alignment

                        Text(email)
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                }
                .accessibilityLabel("Email: \(email), link")
            }

            // Phone link
            if let phone = detail.agent.phone {
                Link(destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!) {
                    HStack(spacing: Spacing.md) { // 12pt gap between icon and text
                        Image(systemName: "phone")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .frame(width: IconSizes.toolbar) // Fixed width for alignment

                        Text(phone)
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                }
                .accessibilityLabel("Phone: \(phone), link")
            }
        }
    }

    /// Primary action button to open Slack channel
    @ViewBuilder
    private func actionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 16))
                Text("Open Slack Channel")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44) // 44pt hit target
            .foregroundStyle(.white)
            .background(Color.blue)
            .cornerRadius(CornerRadius.md) // 12pt corner radius
        }
        .accessibilityLabel("Open Slack Channel, button")
    }

    // MARK: - Helpers

    /// Get agent initials for avatar placeholder
    private var agentInitials: String {
        let components = detail.agent.name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(detail.agent.name.prefix(2))
    }

    /// Format timestamp for Slack message
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format created date
    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

// MARK: - Preview

#Preview("Listing Meta Detail Sheet") {
    Color.gray.opacity(0.2)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            DSListingMetaDetailSheet(
                detail: ListingMetaDetail(
                    agent: ListingAgentMeta(
                        id: "realtor_001",
                        name: "Sarah Chen",
                        email: "sarah@example.com",
                        phone: "+1 (555) 123-4567",
                        slackUserId: "U01ABC123"
                    ),
                    slackMessage: SlackMessage(
                        id: "msg_001",
                        taskId: "task_001",
                        channelId: "C123ABC",
                        threadTs: "123.456",
                        messageTs: "123.456",
                        authorName: "John Doe",
                        text: "Great property on Main Street. Needs follow-up with the listing agent about the open house schedule.",
                        timestamp: Date().addingTimeInterval(-7200) // 2 hours ago
                    ),
                    createdDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                    channelId: "C123ABC"
                ),
                onOpenSlackChannel: { print("Open Slack channel") }
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
        }
}

#Preview("Without Slack Message") {
    Color.gray.opacity(0.2)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            DSListingMetaDetailSheet(
                detail: ListingMetaDetail(
                    agent: ListingAgentMeta(
                        id: "realtor_002",
                        name: "John Doe",
                        email: "john@example.com",
                        phone: nil,
                        slackUserId: nil
                    ),
                    slackMessage: nil,
                    createdDate: Date().addingTimeInterval(-86400 * 7), // 1 week ago
                    channelId: nil
                ),
                onOpenSlackChannel: nil
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
        }
}
