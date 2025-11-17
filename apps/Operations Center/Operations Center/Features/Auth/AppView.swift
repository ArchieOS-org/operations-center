//
//  AppView.swift
//  Operations Center
//
//  Root view with authentication routing
//

import SwiftUI

// MARK: - App View

/// Root view that handles authentication routing
///
/// Shows splash screen → login screen → main app based on auth state
///
/// Flow:
/// 1. isRestoring = true → SplashScreenView
/// 2. isRestoring = false && !isAuthenticated → LoginView
/// 3. isRestoring = false && isAuthenticated → RootView
///
/// Session restoration happens silently in `.task` modifier
struct AppView: View {
    @State private var authStore = AuthenticationStore(supabaseClient: supabase)
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            if authStore.isRestoring {
                // Splash screen during session restoration
                SplashScreenView()
                    .transition(.opacity)
            } else if authStore.isAuthenticated {
                // Main app
                RootView()
                    .transition(.opacity)
            } else {
                // Login screen
                LoginView(store: authStore)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authStore.isRestoring)
        .animation(.easeInOut(duration: 0.3), value: authStore.isAuthenticated)
        .task {
            // Restore session on app launch
            await authStore.restoreSession()
        }
    }
}

// MARK: - Preview

#Preview {
    AppView()
        .environment(AppState(
            supabase: supabase,
            taskRepository: .preview
        ))
}
