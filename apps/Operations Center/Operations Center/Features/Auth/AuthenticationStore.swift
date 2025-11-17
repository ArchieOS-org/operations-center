//
//  AuthenticationStore.swift
//  Operations Center
//
//  Manages authentication state using @Observable pattern
//

import Foundation
import Observation
import Supabase
import Auth

// MARK: - Authentication Store

/// Authentication store with @Observable pattern
///
/// Responsibilities:
/// - Manage authentication state (isAuthenticated, currentUser)
/// - Handle login/logout actions
/// - Restore sessions on app launch
/// - Emit auth state changes for UI routing
///
/// Usage:
/// ```swift
/// @State private var authStore = AuthenticationStore(supabaseClient: supabase)
/// await authStore.login(email: "user@example.com", password: "password")
/// ```
@MainActor
@Observable
final class AuthenticationStore {
    // MARK: - State

    /// Is user authenticated?
    var isAuthenticated = false

    /// Current authenticated user
    var currentUser: Supabase.User?

    /// Loading state during auth operations
    var isLoading = false

    /// Restoring session on app launch
    var isRestoring = true

    /// Authentication error if sign-in fails
    var error: AuthError?

    // MARK: - Dependencies

    private let supabaseClient: SupabaseClient

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    // MARK: - Actions

    /// Sign in with email and password
    func login(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let session = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )

            currentUser = session.user
            isAuthenticated = true
        } catch let authError as Auth.AuthError {
            self.error = .supabaseError(authError)
        } catch {
            self.error = .unknown(error)
        }

        isLoading = false
    }

    /// Sign up new user with email, password, and team
    func signup(email: String, password: String, team: Team) async {
        isLoading = true
        error = nil

        do {
            let session = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["team": .string(team.rawValue)]
            )

            currentUser = session.user
            isAuthenticated = true
        } catch let authError as Auth.AuthError {
            // Map Supabase errors to friendly signup errors
            // Check structured error code for duplicate email
            let errorCode = authError.errorCode

            if errorCode == .emailExists || errorCode == .userAlreadyExists {
                self.error = .emailAlreadyInUse
            } else {
                // Defensive fallback: check message content if error code isn't available
                let message = authError.localizedDescription.lowercased()
                let isDuplicateEmail = message.contains("already registered") ||
                    message.contains("already exists") ||
                    message.contains("user already exists")

                if isDuplicateEmail {
                    self.error = .emailAlreadyInUse
                } else {
                    self.error = .supabaseError(authError)
                }
            }
        } catch {
            // Consistent error mapping with login
            self.error = .unknown(error)
        }

        isLoading = false
    }

    /// Sign in with Google OAuth
    func signInWithGoogle() async {
        isLoading = true
        error = nil

        do {
            // Supabase will open Safari for OAuth flow
            // Callback handled by .onOpenURL in AppView
            try await supabaseClient.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "Noah.Operations-Center://callback")
            )
        } catch let authError as Auth.AuthError {
            self.error = .oauthFailed(authError)
        } catch {
            self.error = .unknown(error)
        }

        isLoading = false
    }

    /// Sign out current user
    func logout() async {
        isLoading = true

        do {
            try await supabaseClient.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            error = nil
        } catch {
            self.error = .logoutFailed
        }

        isLoading = false
    }

    /// Restore session from Keychain on app launch
    func restoreSession() async {
        defer { isRestoring = false }

        do {
            // Try to get existing session (auto-refreshed if needed)
            let session = try await supabaseClient.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            // TEMPORARY DEBUG - Use NSLog for physical device
            NSLog("🔍 Session restoration failed:")
            NSLog("   Error: \(error)")
            NSLog("   Type: \(type(of: error))")
            if let authError = error as? Auth.AuthError {
                NSLog("   Auth Error: \(authError)")
                NSLog("   Localized: \(authError.localizedDescription)")
            }

            // No valid session - user needs to sign in
            isAuthenticated = false
        }
    }
}

// MARK: - Team

/// User team selection
enum Team: String, CaseIterable {
    case marketing = "MARKETING"
    case admin = "ADMIN"

    var displayName: String {
        switch self {
        case .marketing: return "Marketing"
        case .admin: return "Admin"
        }
    }

    var description: String {
        switch self {
        case .marketing: return "Create and manage property listings"
        case .admin: return "Full system access and team management"
        }
    }
}

// MARK: - Auth Error

/// Typed authentication errors with localized messages
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse
    case signupFailed
    case networkError
    case logoutFailed
    case oauthFailed(Auth.AuthError)
    case oauthCancelled
    case supabaseError(Auth.AuthError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email address"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .userNotFound:
            return "No account found with this email"
        case .invalidCredentials:
            return "Email or password is incorrect"
        case .emailAlreadyInUse:
            return "Email already registered"
        case .signupFailed:
            return "Account creation failed"
        case .networkError:
            return "Network connection failed"
        case .logoutFailed:
            return "Failed to sign out"
        case .oauthFailed(let error):
            return "Google sign-in failed: \(error.localizedDescription)"
        case .oauthCancelled:
            return "Sign-in cancelled"
        case .supabaseError(let error):
            return error.localizedDescription
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Check your email format (example@domain.com)"
        case .weakPassword:
            return "Use at least 8 characters"
        case .userNotFound:
            return "Create an account or use a different email"
        case .invalidCredentials:
            return "Double-check your credentials and try again"
        case .emailAlreadyInUse:
            return "Try signing in instead, or use a different email"
        case .signupFailed:
            return "Check your email and password, then try again"
        case .networkError:
            return "Check your internet connection"
        case .oauthFailed:
            return "Try again or use email sign-in"
        case .oauthCancelled:
            return "Tap Google sign-in to try again"
        default:
            return nil
        }
    }
}

// MARK: - Equatable Conformance

extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidEmail, .invalidEmail),
             (.weakPassword, .weakPassword),
             (.userNotFound, .userNotFound),
             (.invalidCredentials, .invalidCredentials),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.signupFailed, .signupFailed),
             (.networkError, .networkError),
             (.logoutFailed, .logoutFailed),
             (.oauthCancelled, .oauthCancelled):
            return true
        case let (.oauthFailed(lhs), .oauthFailed(rhs)):
            return lhs.localizedDescription == rhs.localizedDescription
        case let (.supabaseError(lhs), .supabaseError(rhs)):
            return lhs.localizedDescription == rhs.localizedDescription
        case let (.unknown(lhs), .unknown(rhs)):
            return type(of: lhs) == type(of: rhs) && lhs.localizedDescription == rhs.localizedDescription
        default:
            return false
        }
    }
}
