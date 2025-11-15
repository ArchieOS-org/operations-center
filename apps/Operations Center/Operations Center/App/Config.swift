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
            // Always return production for real implementations
            // swift-dependencies handles preview mode automatically
            return .production
        }
    }

    // MARK: - Supabase Configuration

    static var supabaseURL: URL {
        // Production URL - swift-dependencies handles preview mode
        return URL(string: "https://kukmshbkzlskyuacgzbo.supabase.co")!
    }

    static var supabaseAnonKey: String {
        // Production key - swift-dependencies handles preview mode
        return "sb_publishable_lMBva69x9lCLnWU2fNDB9g_ZY-McsO9"
    }

    // MARK: - FastAPI Configuration

    static var fastAPIURL: URL {
        // swiftlint:disable:next todo
        // TODO: Replace with actual Vercel deployment URL
        return URL(string: "https://your-project.vercel.app")!
    }
}
