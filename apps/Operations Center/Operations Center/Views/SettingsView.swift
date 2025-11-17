//
//  SettingsView.swift
//  Operations Center
//
//  Settings screen
//

import SwiftUI
import OperationsCenterKit
import Supabase
import Auth

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var authStore = AuthenticationStore(supabaseClient: supabase)
    @State private var selectedTeam: Team?
    @State private var isUpdatingTeam = false
    @State private var showingLogoutConfirmation = false
    @State private var hasInitialized = false

    var body: some View {
        List {
            // User Profile Section
            if let user = appState.currentUser {
                Section {
                    LabeledContent("Email", value: user.email ?? "No email")

                    // Team Selection
                    Picker("Team", selection: Binding(
                        get: { selectedTeam ?? currentTeam },
                        set: { newTeam in
                            selectedTeam = newTeam
                            if let newTeam, newTeam != currentTeam, hasInitialized {
                                Task { await updateTeam(newTeam) }
                            }
                        }
                    )) {
                        ForEach(Team.allCases, id: \.self) { team in
                            Text(team.displayName).tag(team as Team?)
                        }
                    }
                    .disabled(isUpdatingTeam)

                    if isUpdatingTeam {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Updating team...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Your team determines your access level and responsibilities")
                }
            }

            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            } header: {
                Text("About")
            }

            Section {
                Link(destination: URL(string: "https://conductor.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://conductor.app/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://conductor.app/support")!) {
                    HStack {
                        Text("Support")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Logout Section
            if appState.currentUser != nil {
                Section {
                    Button(role: .destructive, action: { showingLogoutConfirmation = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Settings")
        .confirmationDialog("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task { await handleLogout() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            selectedTeam = currentTeam
            hasInitialized = true
        }
    }

    // MARK: - Helpers

    private var currentTeam: Team? {
        guard let user = appState.currentUser,
              let teamString = user.userMetadata["team"]?.stringValue else {
            return nil
        }
        return Team(rawValue: teamString)
    }

    // MARK: - Actions

    private func updateTeam(_ team: Team) async {
        isUpdatingTeam = true

        do {
            try await supabase.auth.update(
                user: UserAttributes(
                    data: ["team": .string(team.rawValue)]
                )
            )
        } catch {
            // Revert on error
            selectedTeam = currentTeam
        }

        isUpdatingTeam = false
    }

    private func handleLogout() async {
        await authStore.logout()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState(supabase: supabase, taskRepository: .preview))
    }
}
