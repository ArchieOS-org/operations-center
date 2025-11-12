//
//  StrayTaskToolbar.swift
//  OperationsCenterKit
//
//  Simple toolbar for stray tasks: Claim + Delete
//  No menus on first ship
//

import SwiftUI

/// Toolbar for stray task cards with primary actions
struct StrayTaskToolbar: View {
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
            Text("Update CRM with Q4 contacts")
                .font(Typography.cardTitle)

            StrayTaskToolbar(
                onClaim: { print("Claim tapped") },
                onDelete: { print("Delete tapped") }
            )
        }
        .padding()
        .background(Colors.strayCardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: Shadows.cardShadow, radius: 8, x: 0, y: 2)

        Divider()

        // In expanded card
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Instagram reels")
                .font(Typography.cardTitle)

            Text("Marketing task for open house")
                .font(Typography.callout)
                .foregroundStyle(.secondary)

            StrayTaskToolbar(
                onClaim: { print("Claim tapped") },
                onDelete: { print("Delete tapped") }
            )
        }
        .padding()
        .background(Colors.strayCardBackground)
        .cornerRadius(CornerRadius.card)
        .shadow(color: Shadows.cardShadow, radius: 8, x: 0, y: 2)
    }
    .padding()
}
