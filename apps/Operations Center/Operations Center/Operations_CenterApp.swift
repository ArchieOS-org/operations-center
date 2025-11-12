//
//  Operations_CenterApp.swift
//  Operations Center
//
//  Created by Noah Deskin on 2025-11-11.
//

import SwiftUI
import OperationsCenterKit

@main
struct Operations_CenterApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
