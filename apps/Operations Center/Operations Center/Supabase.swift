//
//  Supabase.swift
//  Operations Center
//
//  Global Supabase client with lazy initialization
//  Reference: Apple's lazy singleton pattern + Swift Testing best practices
//

import Foundation
import Supabase
import OSLog

// MARK: - Lazy Singleton

private var _supabaseClient: SupabaseClient?
private let supabaseLock = NSLock()

/// Global Supabase client - lazily initialized on first access
/// This avoids race conditions between module loading and test environment setup
var supabase: SupabaseClient {
    supabaseLock.lock()
    defer { supabaseLock.unlock() }

    if let existing = _supabaseClient {
        return existing
    }

    // Initialize on first access - at this point, test env is fully ready
    let client = buildSupabaseClient()
    _supabaseClient = client
    return client
}

// MARK: - Builder

private func buildSupabaseClient() -> SupabaseClient {
    // 1. Swift Testing environment - use stub client
    if isRunningSwiftTests() {
        Logger.database.info("🧪 Swift Testing environment - using stub client")
        return SupabaseClient(
            supabaseURL: URL(string: "https://test.supabase.co")!,
            supabaseKey: "test-key-stub"
        )
    }

    // 2. Preview mode (--use-preview-data flag) - use stub client
    if CommandLine.arguments.contains("--use-preview-data") {
        Logger.database.info("📱 Preview mode - using stub client")
        return SupabaseClient(
            supabaseURL: URL(string: "https://preview.supabase.co")!,
            supabaseKey: "preview-key-stub"
        )
    }

    // 3. Production initialization - requires environment variables
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
                    redirectToURL: URL(string: "operationscenter://")!,
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
        // 4. Development fallback - missing config in DEBUG builds
        #if DEBUG
        Logger.database.warning("⚠️ Missing Supabase config in DEBUG - using stub client")
        Logger.database.warning("   Run with 'Operations Center Preview' scheme OR set environment variables")
        return SupabaseClient(
            supabaseURL: URL(string: "https://dev-stub.supabase.co")!,
            supabaseKey: "dev-stub-key"
        )
        #else
        // Release builds MUST have config - fail loudly
        fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - Test Detection

private func isRunningSwiftTests() -> Bool {
    // Swift Testing detection - runs AFTER test environment is fully initialized
    // This is reliable because lazy initialization defers execution

    // 1. Swift Testing session ID (most reliable)
    if ProcessInfo.processInfo.environment["XCTEST_RUN_ID"] != nil {
        return true
    }

    // 2. XCTest configuration path (XCTest framework)
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
        return true
    }

    // 3. Check loaded bundles (test bundles are now loaded)
    for bundle in Bundle.allBundles {
        if let identifier = bundle.bundleIdentifier {
            if identifier.contains("Test") || identifier.contains("XCTest") {
                return true
            }
        }
    }

    // 4. Process name check
    if ProcessInfo.processInfo.processName.lowercased().contains("xctest") {
        return true
    }

    // 5. Command line arguments
    let processName = CommandLine.arguments.first ?? ""
    if processName.contains("test") || processName.contains("xctest") {
        return true
    }

    return false
}
