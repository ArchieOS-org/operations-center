//
//  OCSectionHeader.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Standard section header with optional count badge
public struct OCSectionHeader: View {
    private let title: String
    private let count: Int?

    public init(
        title: String,
        count: Int? = nil
    ) {
        self.title = title
        self.count = count
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(title.uppercased())
                .font(Typography.cardMeta)
                .foregroundStyle(Color.secondary)

            if let count {
                Text("\(count)")
                    .font(Typography.chipLabel)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Colors.surfaceSecondary)
                    )
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.sm)
    }
}