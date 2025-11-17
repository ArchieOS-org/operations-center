//
//  AuthClient.swift
//  Operations Center
//
//  Authentication client for managing current user context
//

import Foundation
import Dependencies
import Supabase

// MARK: - Auth Client

/// Authentication client for managing current user ID
///
/// Design Philosophy:
/// - Single source of truth for current user
/// - Dependency-injected for testability
/// - Swappable for previews and tests
/// - Async-first for proper Supabase session handling
///
/// Usage:
/// ```swift
/// @Dependency(\.authClient) var authClient
/// let userId = await authClient.currentUserId()
/// ```
public struct AuthClient {
    /// Get the current authenticated user ID
    /// Returns the Supabase session user ID, or falls back to Sarah's ID
    public var currentUserId: @Sendable () async -> String

    public init(currentUserId: @escaping @Sendable () async -> String) {
        self.currentUserId = currentUserId
    }
}

// MARK: - Dependency Key

extension AuthClient: DependencyKey {
    /// Live implementation - returns actual authenticated user ID from Supabase
    /// Pattern from Context7: `try await supabase.auth.session`
    /// Falls back to Sarah's ID (first staff member in seed data) if no session exists
    public static let liveValue = AuthClient(
        currentUserId: {
            guard let session = try? await supabase.auth.session else {
                return "01JCQM1A0000000000000001" // Sarah's ID from seed data
            }
            return session.user.id.uuidString
        }
    )
}

// MARK: - Test Dependency Key

extension AuthClient: TestDependencyKey {
    /// Preview implementation - returns preview user ID
    public static let previewValue = AuthClient(
        currentUserId: { "preview-staff-id" }
    )

    /// Test implementation - returns test user ID
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
