//
//  AuthClient.swift
//  Operations Center
//
//  Authentication client for managing current user context
//

import Foundation
import Dependencies
import Supabase

// MARK: - Auth Errors

public enum AuthError: Error, LocalizedError {
    case noSession
    case sessionExpired
    case invalidSession

    public var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active session found. Please sign in."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidSession:
            return "Invalid session. Please sign in again."
        }
    }
}

// MARK: - Auth Client

/// Authentication client for managing current user ID
///
/// Design Philosophy:
/// - Single source of truth for current user
/// - Dependency-injected for testability
/// - Swappable for previews and tests
/// - Async-first for proper Supabase session handling
/// - **Explicit error handling** - Never fakes authentication
///
/// Usage:
/// ```swift
/// @Dependency(\.authClient) var authClient
/// do {
///     let userId = try await authClient.currentUserId()
/// } catch {
///     // Handle auth error
/// }
/// ```
public struct AuthClient {
    /// Get the current authenticated user ID
    /// Throws AuthError if no valid session exists
    public var currentUserId: @Sendable () async throws -> String

    public init(currentUserId: @escaping @Sendable () async throws -> String) {
        self.currentUserId = currentUserId
    }
}

// MARK: - Dependency Key

extension AuthClient: DependencyKey {
    /// Live implementation - returns actual authenticated user ID from Supabase
    /// Throws AuthError.noSession if user is not authenticated
    /// Never returns a fake/fallback ID - fails explicitly
    public static let liveValue = AuthClient(
        currentUserId: {
            do {
                guard let session = try await supabase.auth.session else {
                    throw AuthError.noSession
                }
                return session.user.id.uuidString
            } catch let error as AuthError {
                throw error
            } catch {
                // Wrap Supabase errors in AuthError
                throw AuthError.invalidSession
            }
        }
    )
}

// MARK: - Test Dependency Key

extension AuthClient: TestDependencyKey {
    /// Preview implementation - returns preview user ID
    /// Never throws for previews to keep UI working
    public static let previewValue = AuthClient(
        currentUserId: { "preview-staff-id" }
    )

    /// Test implementation - returns test user ID
    /// Never throws for tests unless explicitly configured
    public static let testValue = AuthClient(
        currentUserId: { "test-staff-id" }
    )
}

// MARK: - Dependency Values

public extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
