//
//  Supabase.swift
//  Operations Center
//
//  Global Supabase client singleton
//  Reference: Supabase Swift SDK official pattern
//

import Foundation
import Supabase

/// Global production Supabase client
/// Initialized lazily on first access - no blocking during app launch
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!,
    supabaseKey: "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9",
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

// MARK: - Preview Support

extension SupabaseClient {
    /// Mock Supabase client for Xcode previews
    /// Uses fake URL that will never be contacted
    static let preview = SupabaseClient(
        supabaseURL: URL(string: "https://preview.supabase.co")!,
        supabaseKey: "preview-anon-key"
    )
}
