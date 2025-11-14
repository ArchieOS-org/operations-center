//
//  Config.swift
//  Operations Center
//
//  Configuration for environment-specific settings
//

import Foundation

enum AppConfig {
    // MARK: - Environment

    enum Environment {
        case production
        case local
        case preview

        static var current: Environment {
            // Use compile-time conditional compilation for environment detection
            // Reference: External Research - Launch arguments only work when Xcode launches app
            // Reference: Context7 - swift-dependencies compile-time detection
            #if DEBUG
            return .preview  // All DEBUG builds use preview data (simulator + device)
            #else
            return .production  // Release builds use production
            #endif
        }
    }

    // MARK: - Supabase Configuration

    static var supabaseURL: URL {
        switch Environment.current {
        case .production:
            return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
        case .local:
            return URL(string: "http://127.0.0.1:54321")!
        case .preview:
            return URL(string: "https://preview.supabase.co")!
        }
    }

    static var supabaseAnonKey: String {
        switch Environment.current {
        case .production:
            return "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9"
        case .local:
            // Local dev anon key from Supabase CLI
            // This is safe to commit - only works locally
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        case .preview:
            return "preview-anon-key"
        }
    }

    // MARK: - FastAPI Configuration

    static var fastAPIURL: URL {
        switch Environment.current {
        case .production:
            // TODO: Replace with actual Vercel deployment URL
            return URL(string: "https://your-project.vercel.app")!
        case .local:
            return URL(string: "http://localhost:8000")!
        case .preview:
            return URL(string: "http://preview.localhost:8000")!
        }
    }
}
