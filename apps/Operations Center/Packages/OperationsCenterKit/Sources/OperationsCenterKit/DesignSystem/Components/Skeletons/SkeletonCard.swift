//
//  SkeletonCard.swift
//  OperationsCenterKit
//
//  Skeleton loading state for cards
//

import SwiftUI

/// Skeleton loading placeholder that matches TaskCard/ActivityCard structure
public struct SkeletonCard: View {
    private let tintColor: Color

    public init(tintColor: Color = .gray.opacity(0.2)) {
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header (title + chips + due date)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Title
                RoundedRectangle(cornerRadius: 4)
                    .fill(tintColor)
                    .frame(height: 16)
                    .frame(maxWidth: 200, alignment: .leading)

                // Chips row
                HStack(spacing: Spacing.xs) {
                    Capsule()
                        .fill(tintColor)
                        .frame(width: 60, height: 20)

                    Capsule()
                        .fill(tintColor)
                        .frame(width: 80, height: 20)
                }
            }

            // Description lines
            VStack(spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(tintColor)
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(tintColor)
                    .frame(height: 14)
                    .frame(maxWidth: 250, alignment: .leading)
            }

            // Metadata row
            HStack(spacing: Spacing.md) {
                // Created date
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tintColor)
                        .frame(width: 40, height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(tintColor)
                        .frame(width: 60, height: 12)
                }

                // Due date
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tintColor)
                        .frame(width: 30, height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(tintColor)
                        .frame(width: 70, height: 12)
                }

                Spacer()
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Colors.surfaceSecondary)
        .cornerRadius(CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Shimmer Modifier

/// Pulsing animation for skeleton states
public struct SkeletonShimmer: ViewModifier {
    @State private var isAnimating = false

    public func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

public extension View {
    /// Apply skeleton shimmer animation
    func skeletonShimmer() -> some View {
        modifier(SkeletonShimmer())
    }
}

// MARK: - Preview

#Preview("Task Skeleton") {
    VStack(spacing: Spacing.md) {
        SkeletonCard(tintColor: Colors.surfaceAgentTaskTinted)
            .skeletonShimmer()

        SkeletonCard(tintColor: Colors.surfaceListingTinted)
            .skeletonShimmer()
    }
    .padding()
    .background(Colors.surfacePrimary)
}
