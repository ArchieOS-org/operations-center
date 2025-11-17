//
//  SplashScreenView.swift
//  Operations Center
//
//  Splash screen shown during session restoration
//

import SwiftUI
import OperationsCenterKit

// MARK: - Splash Screen View

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Colors.accentPrimary,
                    Colors.accentPrimary.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: Spacing.xl) {
                // Logo
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Operations Center")

                // Title
                Text("Operations Center")
                    .font(Typography.largeTitle)
                    .foregroundStyle(.white)

                // Loading Indicator
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Operations Center, loading")
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
