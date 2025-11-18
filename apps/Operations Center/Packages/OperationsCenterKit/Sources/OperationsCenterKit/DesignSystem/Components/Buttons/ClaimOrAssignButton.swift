//
//  ClaimOrAssignButton.swift
//  OperationsCenterKit
//
//  Press to claim, hold to assign button
//  Implements the core interaction pattern for task/activity claiming
//

import SwiftUI

public struct ClaimOrAssignButton: View {
    public let onClaim: () async -> Void
    public let onAssignTapped: () -> Void

    @State private var isPressing = false
    @State private var pressProgress: Double = 0
    @State private var isClaiming = false

    private let longPressDuration: Double = 0.5

    public init(
        onClaim: @escaping () async -> Void,
        onAssignTapped: @escaping () -> Void
    ) {
        self.onClaim = onClaim
        self.onAssignTapped = onAssignTapped
    }

    public var body: some View {
        ZStack {
            // Progress ring (fills during hold)
            Circle()
                .trim(from: 0, to: pressProgress)
                .stroke(Colors.accentPrimary, lineWidth: 3)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))

            // Icon
            Group {
                if isClaiming {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Colors.accentPrimary)
                } else {
                    Image(systemName: "hand.raised.fill")
                        .font(.title3)
                        .foregroundStyle(isPressing ? .secondary : Colors.accentPrimary)
                }
            }
        }
        .frame(width: 44, height: 44)
        .onTapGesture {
            guard !isClaiming else { return }
            isClaiming = true
            Task { 
                await onClaim()
                isClaiming = false
            }
        }
        .onLongPressGesture(
            minimumDuration: longPressDuration,
            perform: handleAssign,
            onPressingChanged: handlePressingChange
        )
        .selectionFeedback(trigger: isPressing)
        .disabled(isClaiming)
        .accessibilityLabel("Claim or assign")
        .accessibilityHint("Tap to claim for yourself, hold to assign to someone else")
    }

    @MainActor
    private func handleClaim() async {
        isClaiming = true
        await onClaim()
        isClaiming = false
    }
    }

    private func handleAssign() {
        pressProgress = 0
        onAssignTapped()
    }

    private func handlePressingChange(_ pressing: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isPressing = pressing
        }

        if pressing {
            // Start progress animation
            withAnimation(.linear(duration: longPressDuration)) {
                pressProgress = 1.0
            }
        } else {
            // Reset progress
            withAnimation(.easeOut(duration: 0.2)) {
                pressProgress = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        ClaimOrAssignButton(
            onClaim: {
                print("Claimed!")
                try? await Task.sleep(for: .seconds(1))
            },
            onAssignTapped: {
                print("Assignment sheet should appear")
            }
        )

        Text("Tap to claim\nHold to assign")
            .multilineTextAlignment(.center)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
