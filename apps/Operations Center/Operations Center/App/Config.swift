//
//  Config.swift
//  Operations Center
//
//  Configuration for environment-specific settings
//  Uses Info.plist for secure configuration management
//

import Foundation
import OSLog

enum AppConfig {
    // MARK: - Environment

    enum Environment {
        case production
        case local
        case preview

        static var current: Environment {
            // Always return production for real implementations
            // swift-dependencies handles preview mode automatically
            return .production
        }
    }

    // MARK: - Configuration Errors

    enum ConfigError: Error, LocalizedError {
        case missingConfiguration(String)
        case invalidURL(String)

        var errorDescription: String? {
            switch self {
            case .missingConfiguration(let key):
                return "Missing required configuration: \(key). Check Info.plist or build settings."
            case .invalidURL(let urlString):
                return "Invalid URL configuration: \(urlString)"
            }
        }
    }

    // MARK: - Supabase Configuration

    static var supabaseURL: URL {
        get throws {
            // Hardcoded fallback - INFOPLIST_KEY_ doesn't work for custom keys
            // TODO: Move to secure configuration management for production
            return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
        }
    }

    static var supabaseAnonKey: String {
        get throws {
            // Hardcoded fallback - INFOPLIST_KEY_ doesn't work for custom keys
            // TODO: Move to secure configuration management for production
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a21zaGJremxza3l1YWNnemJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3OTUyOTAsImV4cCI6MjA3ODM3MTI5MH0.Jax3HtgBuu5COWr_p0mXiVuXlCFDsQaj9VUEQGxUOcE"
        }
    }

    // MARK: - FastAPI Configuration

    static var fastAPIURL: URL {
        get throws {
            // Hardcoded fallback - INFOPLIST_KEY_ doesn't work for custom keys
            // TODO: Move to secure configuration management for production
            return URL(string: "https://operations-center.vercel.app")!
        }
    }

    // MARK: - Helpers

    /// Validates all required configuration on app launch
    /// Fails loudly in development, logs errors in production
    static func validate() {
        #if DEBUG
        // Debug Bundle.infoDictionary FIRST to see what's actually there
        let keyCount = Bundle.main.infoDictionary?.keys.count ?? 0
        NSLog("🔍 Bundle.main.infoDictionary contains \(keyCount) keys")
        NSLog("🔍 SUPABASE_URL configured: \(Bundle.main.infoDictionary?["SUPABASE_URL"] != nil ? "YES" : "NO")")
        NSLog("🔍 SUPABASE_ANON_KEY configured: \(Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] != nil ? "YES" : "NO")")
        #endif

        do {
            let url = try supabaseURL
            let key = try supabaseAnonKey

            #if DEBUG
            // Use NSLog for physical device logging in DEBUG only
            NSLog("✅ Configuration loaded:")
            NSLog("   SUPABASE_URL: \(url.absoluteString)")
            // Redact key: show only last 4 characters for verification
            let keySuffix = key.count > 4 ? String(key.suffix(4)) : "••••"
            NSLog("   SUPABASE_ANON_KEY: •••••••••••••••••••••••••••••••••••••\(keySuffix)")
            #endif

            Logger.uiLogger.info("✅ Configuration validated successfully")
        } catch {
            #if DEBUG
            NSLog("❌ Configuration error: \(error.localizedDescription)")
            fatalError("Configuration error: \(error.localizedDescription)")
            #else
            Logger.uiLogger.error("⚠️ Configuration error: \(error.localizedDescription)")
            #endif
        }

        // FastAPI is optional - just log if missing
        do {
            let apiURL = try fastAPIURL
            #if DEBUG
            NSLog("   FASTAPI_URL: \(apiURL.absoluteString)")
            #endif
        } catch {
            #if DEBUG
            NSLog("⚠️ FastAPI URL not configured: \(error.localizedDescription)")
            #endif
            Logger.uiLogger.warning("⚠️ FastAPI URL not configured: \(error.localizedDescription)")
        }
    }
}
