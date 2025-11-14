//
//  Operations_CenterApp.swift
//  Operations Center
//
//  Created by Noah Deskin on 2025-11-11.
//

import SwiftUI
import Dependencies
import OperationsCenterKit

@main
struct Operations_CenterApp: App {
    @Dependency(\.appState) private var appState

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
