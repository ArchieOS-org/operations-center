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
    static var liveValue: SupabaseClient {
        // Use compile-time environment detection
        // Reference: External Research - Launch arguments don't persist on device
        // Reference: Context7 - swift-dependencies conditional compilation
        if AppConfig.Environment.current == .preview {
            return previewValue
        }

        return SupabaseClient(
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

    static let previewValue: SupabaseClient = {
        // Mock client for previews - won't connect to real Supabase
        SupabaseClient(
            supabaseURL: URL(string: "https://preview.supabase.co")!,
            supabaseKey: "preview-anon-key"
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

// MARK: - TestDependencyKey Conformance

// Use @retroactive to silence Swift 6 warning about retroactive conformance
// This is safe because we own the conformance in our module
extension SupabaseClient: @retroactive TestDependencyKey {
    public static let testValue: SupabaseClient = SupabaseClientKey.testValue
    public static let previewValue: SupabaseClient = SupabaseClientKey.previewValue
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
