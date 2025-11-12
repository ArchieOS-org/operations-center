//
//  SupabaseService.swift
//  Operations Center
//
//  Shared Supabase client instance and service layer
//

import Foundation
import Supabase

/// Shared Supabase client instance
/// Use this throughout the app for all database operations
public final class SupabaseService {
    // MARK: - Shared Instance

    public static let shared = SupabaseService()

    // MARK: - Client

    public let client: SupabaseClient

    // MARK: - Initialization

    private init() {
        self.client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(
                    schema: "public"
                ),
                auth: .init(
                    flowType: .pkce,
                    emitLocalSessionAsInitialSession: true
                ),
                global: .init(
                    headers: ["x-client-info": "operations-center-ios/1.0.0"]
                )
            )
        )
    }
}

// MARK: - Convenience Extensions

public extension SupabaseService {
    /// Direct access to database operations
    var database: PostgrestClient {
        client.database
    }

    /// Direct access to auth operations
    var auth: AuthClient {
        client.auth
    }

    /// Direct access to realtime subscriptions
    var realtime: RealtimeClient {
        client.realtime
    }
}
