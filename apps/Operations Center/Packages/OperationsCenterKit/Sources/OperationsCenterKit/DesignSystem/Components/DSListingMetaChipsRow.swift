import SwiftUI

/// Meta information model for listing agent (used in chips and detail sheet)
public struct ListingAgentMeta {
    public let id: String
    public let name: String
    public let email: String?
    public let phone: String?
    public let slackUserId: String?

    public init(
        id: String,
        name: String,
        email: String? = nil,
        phone: String? = nil,
        slackUserId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.slackUserId = slackUserId
    }
}

/// Extension to convert Realtor to ListingAgentMeta
public extension Realtor {
    var meta: ListingAgentMeta {
        ListingAgentMeta(
            id: id,
            name: name,
            email: email,
            phone: phone,
            slackUserId: slackUserId
        )
    }
}

/// Reusable meta chips row for listing detail screens
///
/// Design Spec (from research):
/// - Horizontal row with Agent chip and Due date chip
/// - Uses existing DSChip component with light background tint (0.15 opacity)
/// - 8pt spacing between chips (Spacing.sm)
/// - Entire row is tappable as a single unit (opens detail sheet)
/// - Left-aligned, scrollable if more chips added in future
///
/// Usage:
/// ```swift
/// DSListingMetaChipsRow(
///     agent: realtor.meta,
///     dueDate: listing.dueDate,
///     onTap: { showDetailSheet = true }
/// )
/// ```
public struct DSListingMetaChipsRow: View {
    // MARK: - Properties

    public let agent: ListingAgentMeta?
    public let dueDate: Date?
    public let onTap: () -> Void

    // MARK: - Initialization

    /// Create a meta chips row
    /// - Parameters:
    ///   - agent: Agent metadata (name, email, phone, Slack ID)
    ///   - dueDate: Due date for the listing (optional)
    ///   - onTap: Action when the entire row is tapped
    public init(
        agent: ListingAgentMeta?,
        dueDate: Date?,
        onTap: @escaping () -> Void
    ) {
        self.agent = agent
        self.dueDate = dueDate
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        // Only show if we have at least one piece of metadata
        if agent != nil || dueDate != nil {
            Button(action: onTap) {
                HStack(spacing: Spacing.sm) { // 8pt gap between chips
                    // Agent chip
                    if let agent = agent {
                        DSChip(agentName: agent.name, style: .agentTask)
                    }

                    // Due date chip
                    if let dueDate = dueDate {
                        DSChip(date: dueDate)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle()) // No default button styling
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double-tap to view details")
        }
    }

    // MARK: - Helpers

    private var accessibilityLabel: String {
        var parts: [String] = []

        if let agent = agent {
            parts.append("Agent: \(agent.name)")
        }

        if let dueDate = dueDate {
            let formatted = dueDate.formatted(.relative(presentation: .named))
            parts.append("Due: \(formatted)")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("Meta Chips Row") {
    VStack(spacing: 32) {
        // Both chips
        DSListingMetaChipsRow(
            agent: ListingAgentMeta(
                id: "realtor_001",
                name: "Sarah Chen",
                email: "sarah@example.com",
                phone: "+1 (555) 123-4567",
                slackUserId: "U01ABC123"
            ),
            dueDate: Date().addingTimeInterval(86400 * 2), // 2 days from now
            onTap: { print("Tapped chips row") }
        )
        .padding(.horizontal, Spacing.screenEdge)
        .background(Colors.surfacePrimary)

        Divider()

        // Only agent chip
        DSListingMetaChipsRow(
            agent: ListingAgentMeta(id: "realtor_002", name: "John Doe"),
            dueDate: nil,
            onTap: { print("Tapped chips row") }
        )
        .padding(.horizontal, Spacing.screenEdge)
        .background(Colors.surfacePrimary)

        Divider()

        // Only due date chip (overdue)
        DSListingMetaChipsRow(
            agent: nil,
            dueDate: Date().addingTimeInterval(-86400), // Yesterday
            onTap: { print("Tapped chips row") }
        )
        .padding(.horizontal, Spacing.screenEdge)
        .background(Colors.surfacePrimary)

        Divider()

        // No chips (should not render)
        DSListingMetaChipsRow(
            agent: nil,
            dueDate: nil,
            onTap: { print("Tapped chips row") }
        )
        .padding(.horizontal, Spacing.screenEdge)
        .background(Colors.surfacePrimary)
    }
    .padding(.vertical)
}
