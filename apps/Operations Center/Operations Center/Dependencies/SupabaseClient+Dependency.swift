//
//  SupabaseClient+Dependency.swift
//  Operations Center
//
//  Created by Claude Code
//

import Foundation
import Dependencies
import Supabase

// MARK: - Dependency Key

private enum SupabaseClientKey: DependencyKey {
    static let liveValue: SupabaseClient = {
        SupabaseClient(
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
    }()

    static let testValue: SupabaseClient = {
        // Test value returns unimplemented client
        // Individual tests should override with mocks
        SupabaseClient(
            supabaseURL: URL(string: "https://test.supabase.co")!,
            supabaseKey: "test-key"
        )
    }()
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
