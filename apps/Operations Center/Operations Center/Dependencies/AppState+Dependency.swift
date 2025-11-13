//
//  AppState+Dependency.swift
//  Operations Center
//
//  Register AppState as a swift-dependencies dependency
//

import Dependencies
import Foundation

private enum AppStateKey: DependencyKey {
    static let liveValue = AppState()
    static let testValue = AppState()
}

extension DependencyValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
