//
//  ActivityToolbar.swift
//  OperationsCenterKit
//
//  Simple toolbar for activities: Claim + Delete
//  No menus on first ship
//

import SwiftUI

/// Toolbar for activity cards with primary actions
struct ActivityToolbar: View {
    // MARK: - Properties

    let onClaim: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Claim button (primary action)
            Button(action: onClaim) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 14))
                    Text("Claim")
                        .font(Typography.callout)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Colors.claimAction)
                .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(.plain)

            Spacer()

            // Delete button (destructive action)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(Colors.deleteAction)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Normal state
        VStack(alignment: .leading, spacing: 12) {
            Text("123 Maple Street pre-listing prep")
                .font(Typography.cardTitle)

            Text("Property listing-001")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)

            ActivityToolbar(
                onClaim: {},
                onDelete: {}
            )
        }
        .padding()
        .background(Colors.cardSystemBackground)
        .cornerRadius(CornerRadius.card)

        Divider()

        // In expanded card with subtasks
        VStack(alignment: .leading, spacing: 12) {
            Text("Marketing campaign")
                .font(Typography.cardTitle)

            Text("456 Oak Avenue")
                .font(Typography.cardSubtitle)
                .foregroundStyle(.secondary)

            // Mock subtasks section
            VStack(alignment: .leading, spacing: 8) {
                Text("SUBTASKS")
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Colors.completeAction)
                    Text("Create social media posts")
                        .font(Typography.callout)
                }

                HStack {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray.opacity(0.3))
                    Text("Design email blast")
                        .font(Typography.callout)
                }
            }

            ActivityToolbar(
                onClaim: {},
                onDelete: {}
            )
        }
        .padding()
        .background(Colors.cardSystemBackground)
        .cornerRadius(CornerRadius.card)
    }
    .padding()
}
