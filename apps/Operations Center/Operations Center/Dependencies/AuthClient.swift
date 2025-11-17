//
//  AuthClient.swift
//  Operations Center
//
//  Authentication client for managing current user context
//

import Foundation
import Dependencies

// MARK: - Auth Client

/// Authentication client for managing current user ID
///
/// Design Philosophy:
/// - Single source of truth for current user
/// - Dependency-injected for testability
/// - Swappable for previews and tests
///
/// Usage:
/// ```swift
/// @Dependency(\.authClient) var authClient
/// let userId = authClient.currentUserId()
/// ```
public struct AuthClient {
    /// Get the current authenticated user ID
    public var currentUserId: @Sendable () -> String

    public init(currentUserId: @escaping @Sendable () -> String) {
        self.currentUserId = currentUserId
    }
}

// MARK: - Dependency Key

extension AuthClient: DependencyKey {
    /// Live implementation - returns actual authenticated user ID
    /// TODO: Replace with real authentication when auth system is implemented
    public static let liveValue = AuthClient(
        currentUserId: { "current-staff-id" }
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
