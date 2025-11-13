//
//  DSContextMenu.swift
//  OperationsCenterKit
//
//  Bottom action menu with liquid glass effect
//

import SwiftUI

// MARK: - Action Model

public struct DSContextAction: Identifiable {
    public let id = UUID()
    public let title: String
    public let systemImage: String
    public let role: ButtonRole?
    public let action: () -> Void

    public init(
        title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }
}

// MARK: - Context Menu Component

public struct DSContextMenu: View {
    // MARK: - Properties

    private let actions: [DSContextAction]

    // MARK: - Initialization

    public init(actions: [DSContextAction]) {
        self.actions = actions
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(actions) { action in
                Button(role: action.role) {
                    action.action()
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                        .font(.body.weight(.medium))
                        .foregroundStyle(action.role == .destructive ? Color.red : Color.primary)
                }
                .buttonStyle(.borderless)

                if action.id != actions.last?.id {
                    Divider()
                        .frame(height: 20)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }
}

// MARK: - Previews

#Preview("Move & Delete") {
    VStack {
        Spacer()
        DSContextMenu(actions: [
            DSContextAction(title: "Move", systemImage: "arrow.right.circle") {
                print("Move tapped")
            },
            DSContextAction(title: "Delete", systemImage: "trash", role: .destructive) {
                print("Delete tapped")
            }
        ])
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}

#Preview("Claim & Delete") {
    VStack {
        Spacer()
        DSContextMenu(actions: [
            DSContextAction(title: "Claim", systemImage: "hand.raised") {
                print("Claim tapped")
            },
            DSContextAction(title: "Delete", systemImage: "trash", role: .destructive) {
                print("Delete tapped")
            }
        ])
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}

#Preview("Multiple Actions") {
    VStack {
        Spacer()
        DSContextMenu(actions: [
            DSContextAction(title: "Edit", systemImage: "pencil") {
                print("Edit tapped")
            },
            DSContextAction(title: "Share", systemImage: "square.and.arrow.up") {
                print("Share tapped")
            },
            DSContextAction(title: "Archive", systemImage: "archivebox") {
                print("Archive tapped")
            },
            DSContextAction(title: "Delete", systemImage: "trash", role: .destructive) {
                print("Delete tapped")
            }
        ])
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}
