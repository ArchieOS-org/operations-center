import SwiftUI

/// Card style enum for chip color differentiation
public enum CardStyle {
    case agentTask
    case activity
}

/// A chip/badge component for displaying labels with colored backgrounds
public struct DSChip: View {
    let text: String
    let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(Typography.chipLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Convenience Initializers

extension DSChip {
    /// Create a chip for displaying a due date with color coding
    public init(date: Date) {
        let isOverdue = date < Date()
        self.text = date.formatted(.relative(presentation: .named))
        self.color = isOverdue ? .red : .orange
    }

    /// Create a chip for displaying an agent name with card-style color
    public init(agentName: String, style: CardStyle) {
        self.text = agentName
        self.color = style == .agentTask ? Colors.agentTaskAccent : Colors.activityAccent
    }
}
