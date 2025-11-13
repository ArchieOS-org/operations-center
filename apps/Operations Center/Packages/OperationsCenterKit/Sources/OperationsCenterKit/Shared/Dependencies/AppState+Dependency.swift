//
//  AppState+Dependency.swift
//  OperationsCenterKit
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
    public var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
