//
//  LoginView.swift
//  Operations Center
//
//  Authentication login screen with Supabase integration
//

import SwiftUI
import OperationsCenterKit

// MARK: - Login View

struct LoginView: View {
    // MARK: - State

    @Bindable var store: AuthenticationStore

    @State private var email = ""
    @State private var password = ""
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var showingSignup = false

    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var a11yFocus: Field?

    enum Field: Hashable {
        case email
        case password
        case signIn
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

                        // Sign In Button
                        signInButton

                        // OAuth Divider
                        oauthDivider

                        // Google Sign In
                        googleSignInButton

                        // Create Account Link
                        createAccountLink

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
                                Text("Signing in...")
                                    .font(Typography.body)
                                    .foregroundStyle(.white)
                            }
                            .padding(Spacing.xl)
                            .background(Colors.surfaceSecondary)
                            .cornerRadius(12)
                        }
                }
            }
            .navigationTitle("Sign In")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showingSignup) {
                SignupView(store: store)
            }
        }
        .onAppear {
            focusedField = .email
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Colors.accentPrimary)
                .accessibilityLabel("Operations Center")

            Text("Operations Center")
                .font(Typography.title)

            Text("Real Estate Management")
                .font(Typography.cardMeta)
                .foregroundStyle(.secondary)
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
                    .accessibilityFocused($a11yFocus, equals: .email)
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
                    .accessibility(label: Text("Email address for sign in"))

                if let error = emailError {
                    errorLabel(error)
                }
            }

            // Password Field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Password", systemImage: "lock.fill")
                    .font(Typography.cardTitle)
                    .accessibility(hidden: true)

                SecureField("••••••••", text: $password)
                    .focused($focusedField, equals: .password)
                    .accessibilityFocused($a11yFocus, equals: .password)
                    .textContentType(.password)
                    .onChange(of: password) { _, newValue in
                        validatePassword(newValue)
                    }
                    .onSubmit {
                        if isFormValid {
                            focusedField = .signIn
                        }
                    }
                    #if !os(macOS)
                    .submitLabel(.go)
                    #endif
                    .textFieldStyle(.roundedBorder)
                    .accessibility(label: Text("Password"))

                if let error = passwordError {
                    errorLabel(error)
                }
            }

            // Authentication Error
            if let error = store.error {
                authErrorView(error)
            }
        }
    }

    private var signInButton: some View {
        Button(
            action: { Task { await handleSignIn() } },
            label: {
                HStack(spacing: Spacing.sm) {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.fill")
                }
                Text("Sign In")
                    .font(Typography.cardTitle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            }
        )
        .focused($focusedField, equals: .signIn)
        .accessibilityFocused($a11yFocus, equals: .signIn)
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(store.isLoading || !isFormValid)
        .accessibility(hint: Text("Sign in with your email and password"))
        .sensoryFeedback(.success, trigger: store.isAuthenticated)
        .sensoryFeedback(trigger: store.error) { _, newError in
            newError != nil ? .error : nil
        }
    }

    private var oauthDivider: some View {
        HStack(spacing: Spacing.md) {
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)

            Text("Or continue with")
                .font(Typography.cardMeta)
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var googleSignInButton: some View {
        Button(
            action: { Task { await handleGoogleSignIn() } },
            label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "g.circle.fill")
                        .font(.title3)
                    Text("Sign in with Google")
                        .font(Typography.cardTitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
        )
        .buttonStyle(.bordered)
        .tint(.primary)
        .disabled(store.isLoading)
    }

    private var createAccountLink: some View {
        Button(
            action: { showingSignup = true },
            label: {
                HStack(spacing: Spacing.xs) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Text("Create one")
                        .foregroundStyle(Colors.accentPrimary)
                        .fontWeight(.semibold)
                }
                .font(Typography.body)
            }
        )
        .buttonStyle(.plain)
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
                Text(error.errorDescription ?? "Sign in failed")
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

    // MARK: - Validation

    private func validateEmail(_ value: String) {
        if value.isEmpty {
            emailError = "Email is required"
        } else if !isValidEmail(value) {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    private func validatePassword(_ value: String) {
        if value.isEmpty {
            passwordError = nil
        } else if value.count < 8 {
            passwordError = "At least 8 characters required"
        } else {
            passwordError = nil
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && emailError == nil &&
        !password.isEmpty && passwordError == nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        // Simple email validation
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // MARK: - Actions

    private func handleSignIn() async {
        await store.login(email: email, password: password)
    }

    private func handleGoogleSignIn() async {
        await store.signInWithGoogle()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var store = AuthenticationStore(supabaseClient: supabase)
    LoginView(store: store)
}
