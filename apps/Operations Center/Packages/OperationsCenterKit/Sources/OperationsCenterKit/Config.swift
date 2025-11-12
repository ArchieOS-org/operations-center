//
//  Config.swift
//  Operations Center
//
//  Configuration for environment-specific settings
//

import Foundation

public enum AppConfig {
    // MARK: - Environment

    public enum Environment {
        case production
        case local

        public static var current: Environment {
            // Force production for now until local dev is set up
            return .production

            // Uncomment for automatic environment switching:
            // #if DEBUG
            // return .local
            // #else
            // return .production
            // #endif
        }
    }

    // MARK: - Supabase Configuration

    public static var supabaseURL: URL {
        switch Environment.current {
        case .production:
            return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
        case .local:
            return URL(string: "http://127.0.0.1:54321")!
        }
    }

    public static var supabaseAnonKey: String {
        switch Environment.current {
        case .production:
            return "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9"
        case .local:
            // Local dev anon key from Supabase CLI
            // This is safe to commit - only works locally
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        }
    }

    // MARK: - FastAPI Configuration

    public static var fastAPIURL: URL {
        switch Environment.current {
        case .production:
            // TODO: Replace with actual Vercel deployment URL
            return URL(string: "https://your-project.vercel.app")!
        case .local:
            return URL(string: "http://localhost:8000")!
        }
    }
}
