//
//  Supabase.swift
//  Operations Center
//
//  Global Supabase client singleton
//  Reference: Supabase Swift SDK official pattern
//

import Foundation
import Supabase
import OSLog

/// Global production Supabase client
/// Initialized lazily on first access - no blocking during app launch
let supabase: SupabaseClient = {
    do {
        let url = try AppConfig.supabaseURL
        let key = try AppConfig.supabaseAnonKey

        Logger.database.info("🔌 Initializing Supabase client")
        Logger.database.debug("   URL: \(url.absoluteString)")

        let client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
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

        Logger.database.info("✅ Supabase client initialized successfully")
        return client
    } catch {
        #if DEBUG
        fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
        #else
        Logger.database.error("❌ Failed to initialize Supabase client: \(error.localizedDescription)")
        // Return a dummy client - app will fail gracefully
        // This should never happen in production with proper configuration
        return SupabaseClient(
            supabaseURL: URL(string: "https://placeholder.supabase.co")!,
            supabaseKey: "placeholder"
        )
        #endif
    }
}()
