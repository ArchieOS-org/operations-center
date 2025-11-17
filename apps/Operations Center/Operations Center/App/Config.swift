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
            // Try environment variable first (for development)
            if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                return url
            }

            // Fall back to Info.plist (for production builds)
            guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  !urlString.isEmpty else {
                throw ConfigError.missingConfiguration("SUPABASE_URL")
            }

            guard let url = URL(string: urlString) else {
                throw ConfigError.invalidURL(urlString)
            }

            return url
        }
    }

    static var supabaseAnonKey: String {
        get throws {
            // Try environment variable first (for development)
            if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
               !key.isEmpty {
                return key
            }

            // Fall back to Info.plist (for production builds)
            guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
                  !key.isEmpty else {
                throw ConfigError.missingConfiguration("SUPABASE_ANON_KEY")
            }

            return key
        }
    }

    // MARK: - FastAPI Configuration

    static var fastAPIURL: URL {
        get throws {
            // Try environment variable first
            if let urlString = ProcessInfo.processInfo.environment["FASTAPI_URL"],
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                return url
            }

            // Fall back to Info.plist
            guard let urlString = Bundle.main.infoDictionary?["FASTAPI_URL"] as? String,
                  !urlString.isEmpty else {
                throw ConfigError.missingConfiguration("FASTAPI_URL")
            }

            guard let url = URL(string: urlString) else {
                throw ConfigError.invalidURL(urlString)
            }

            return url
        }
    }

    // MARK: - Helpers

    /// Validates all required configuration on app launch
    /// Fails loudly in development, logs errors in production
    static func validate() {
        do {
            _ = try supabaseURL
            _ = try supabaseAnonKey
            Logger.uiLogger.info("✅ Configuration validated successfully")
        } catch {
            #if DEBUG
            fatalError("Configuration error: \(error.localizedDescription)")
            #else
            Logger.uiLogger.error("⚠️ Configuration error: \(error.localizedDescription)")
            #endif
        }

        // FastAPI is optional - just log if missing
        do {
            _ = try fastAPIURL
        } catch {
            Logger.uiLogger.warning("⚠️ FastAPI URL not configured: \(error.localizedDescription)")
        }
    }
}
