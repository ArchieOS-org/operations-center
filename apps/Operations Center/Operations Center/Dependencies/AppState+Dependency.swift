//
//  AppState+Dependency.swift
//  Operations Center
//
//  Register AppState as a swift-dependencies dependency
//

import Dependencies
import Foundation

private enum AppStateKey: DependencyKey {
    static var liveValue: AppState {
        // Use compile-time environment detection
        // Reference: External Research - Launch arguments don't persist on device
        // Reference: Context7 - static var liveValue pattern for conditional initialization
        if AppConfig.Environment.current == .preview {
            return previewValue
        }
        return AppState()
    }

    static let previewValue: AppState = {
        withDependencies {
            $0.supabaseClient = .previewValue
            $0.context = .preview
        } operation: {
            AppState()
        }
    }()

    static let testValue = AppState()
}

extension DependencyValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
