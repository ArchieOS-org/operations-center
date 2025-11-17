//
//  OCAgentRow.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Agent list row extracted from AgentsView.RealtorRow and moved into the design system
public struct OCAgentRow: View {
    private let realtor: Realtor
    private let onTap: (() -> Void)?

    public init(
        realtor: Realtor,
        onTap: (() -> Void)? = nil
    ) {
        self.realtor = realtor
        self.onTap = onTap
    }

    public var body: some View {
        OCRow(onTap: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Primary: Agent name
                Text(realtor.name)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Color.primary)

                // Secondary info row
                HStack(spacing: Spacing.md) {
                    // Email (required per Realtor model, checked with isEmpty)
                    // Phone is optional. If model changes to make both optional, update this logic.
                    if !realtor.email.isEmpty {
                        Label {
                            Text(realtor.email)
                                .font(Typography.cardSubtitle)
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "envelope")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    // Phone (if present)
                    if let phone = realtor.phone, !phone.isEmpty {
                        Label {
                            Text(phone)
                                .font(Typography.cardSubtitle)
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "phone")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    Spacer(minLength: 0)
                }

                // Additional info chips
                HStack(spacing: Spacing.sm) {
                    // Brokerage chip (if present)
                    if let brokerage = realtor.brokerage, !brokerage.isEmpty {
                        DSChip(
                            text: brokerage,
                            color: Colors.accentListing
                        )
                    }

                    // Territory chips
                    ForEach(realtor.territories.prefix(2), id: \.self) { territory in
                        DSChip(
                            text: territory,
                            color: Color.secondary
                        )
                    }

                    // Show count if more territories
                    if realtor.territories.count > 2 {
                        Text("+\(realtor.territories.count - 2)")
                            .font(Typography.chipLabel)
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer(minLength: 0)
                }
            }
        } accessory: {
            // Status badge if not active
            if realtor.status != .active {
                Text(realtor.status.displayName)
                    .font(Typography.chipLabel)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}