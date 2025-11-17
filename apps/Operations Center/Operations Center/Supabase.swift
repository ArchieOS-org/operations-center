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
    let url = URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
    let key = "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9"
    
    Logger.database.info("🔌 Initializing Supabase client...")
    Logger.database.info("   URL: \(url.absoluteString)")
    Logger.database.info("   Key: \(key.prefix(20))...")
    
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
}()
