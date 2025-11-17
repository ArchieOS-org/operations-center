//
//  SignupView.swift
//  Operations Center
//
//  Account creation with email, password, and team selection
//

import SwiftUI
import OperationsCenterKit

// MARK: - Signup View

// swiftlint:disable type_body_length
struct SignupView: View {
    // MARK: - State

    @Bindable var store: AuthenticationStore
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedTeam: Team?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Colors.surfacePrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        header

                        // Form
                        form
                            .padding(Spacing.lg)
                            .background(Colors.surfaceSecondary)
                            .cornerRadius(12)

                        // Team Selection
                        teamSelection

                        // Create Account Button
                        createAccountButton

                        Spacer()
                    }
                    .padding(Spacing.screenEdge)
                }
                #if !os(macOS)
                .scrollDismissesKeyboard(.interactively)
                #endif

                // Loading Overlay
                if store.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: Spacing.md) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Creating account...")
                                    .font(Typography.body)
                                    .foregroundStyle(.white)
                            }
                            .padding(Spacing.xl)
                            .background(Colors.surfaceSecondary)
                            .cornerRadius(12)
                        }
                }
            }
            .navigationTitle("Create Account")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            focusedField = .email
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(Colors.accentPrimary)

            Text("Join Operations Center")
                .font(Typography.title)

            Text("Create your account and select your team")
                .font(Typography.cardMeta)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    private var form: some View {
        VStack(spacing: Spacing.lg) {
            // Email Field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Email Address", systemImage: "envelope.fill")
                    .font(Typography.cardTitle)
                    .accessibility(hidden: true)

                TextField("you@example.com", text: $email)
                    .focused($focusedField, equals: .email)
                    #if !os(macOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    #endif
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .onChange(of: email) { _, newValue in
                        validateEmail(newValue)
                    }
                    .onSubmit { focusedField = .password }
                    .textFieldStyle(.roundedBorder)

                if let error = emailError {
                    errorLabel(error)
                }
            }

            // Password Field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Password", systemImage: "lock.fill")
                    .font(Typography.cardTitle)
                    .accessibility(hidden: true)

                SecureField("At least 8 characters", text: $password)
                    .focused($focusedField, equals: .password)
                    .onChange(of: password) { _, newValue in
                        validatePassword(newValue)
                    }
                    .onSubmit { focusedField = .confirmPassword }
                    #if !os(macOS)
                    .submitLabel(.next)
                    #endif
                    .textFieldStyle(.roundedBorder)

                if let error = passwordError {
                    errorLabel(error)
                }
            }

            // Confirm Password Field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Confirm Password", systemImage: "lock.fill")
                    .font(Typography.cardTitle)
                    .accessibility(hidden: true)

                SecureField("Re-enter password", text: $confirmPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .onChange(of: confirmPassword) { _, newValue in
                        validateConfirmPassword(newValue)
                    }
                    .onSubmit {
                        focusedField = nil
                    }
                    #if !os(macOS)
                    .submitLabel(.done)
                    #endif
                    .textFieldStyle(.roundedBorder)

                if let error = confirmPasswordError {
                    errorLabel(error)
                }
            }

            // Authentication Error
            if let error = store.error {
                authErrorView(error)
            }
        }
    }

    private var teamSelection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Select Your Team", systemImage: "person.2.fill")
                    .font(Typography.cardTitle)

                Text("You can change this later in Settings")
                    .font(Typography.cardMeta)
                    .foregroundStyle(.secondary)
            }

            ForEach(Team.allCases, id: \.self) { team in
                TeamSelectionCard(
                    team: team,
                    isSelected: selectedTeam == team,
                    action: { selectedTeam = team }
                )
            }
        }
    }

    private var createAccountButton: some View {
        Button(
            action: { Task { await handleSignup() } },
            label: {
                HStack(spacing: Spacing.sm) {
                    if store.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                    }
                    Text("Create Account")
                        .font(Typography.cardTitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
        )
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(store.isLoading || !isFormValid)
    }

    private func errorLabel(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(Typography.cardMeta)
            .foregroundStyle(Colors.actionDestructive)
    }

    private func authErrorView(_ error: AuthError) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Colors.actionDestructive)
                Text(error.errorDescription ?? "Signup failed")
                    .font(Typography.callout)
                    .fontWeight(.medium)
            }
            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(Typography.cardMeta)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Colors.actionDestructive.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Actions

    private func handleSignup() async {
        guard let team = selectedTeam else { return }
        await store.signup(email: email, password: password, team: team)
    }
}

// MARK: - Validation Helpers

private extension SignupView {
    func validateEmail(_ value: String) {
        if value.isEmpty {
            emailError = "Email is required"
        } else if !isValidEmail(value) {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    func validatePassword(_ value: String) {
        if value.isEmpty {
            passwordError = nil
        } else if value.count < 8 {
            passwordError = "At least 8 characters required"
        } else {
            passwordError = nil
        }

        // Re-validate confirm password if it exists
        if !confirmPassword.isEmpty {
            validateConfirmPassword(confirmPassword)
        }
    }

    func validateConfirmPassword(_ value: String) {
        if value.isEmpty {
            confirmPasswordError = nil
        } else if value != password {
            confirmPasswordError = "Passwords don't match"
        } else {
            confirmPasswordError = nil
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    var isFormValid: Bool {
        !email.isEmpty &&
        emailError == nil &&
        !password.isEmpty &&
        password.count >= 8 &&
        passwordError == nil &&
        password == confirmPassword &&
        selectedTeam != nil
    }
}

// MARK: - Team Selection Card

private struct TeamSelectionCard: View {
    let team: Team
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Colors.accentPrimary : .secondary)

                // Team Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(team.displayName)
                        .font(Typography.cardTitle)
                        .foregroundStyle(isSelected ? Colors.accentPrimary : .primary)

                    Text(team.description)
                        .font(Typography.cardMeta)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(isSelected ? Colors.accentPrimary.opacity(0.1) : Colors.surfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Colors.accentPrimary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Signup View") {
    SignupView(store: AuthenticationStore(supabaseClient: supabase))
}
