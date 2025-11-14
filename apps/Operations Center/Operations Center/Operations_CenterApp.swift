//
//  Operations_CenterApp.swift
//  Operations Center
//
//  Created by Noah Deskin on 2025-11-11.
//

import SwiftUI
import OperationsCenterKit

@MainActor
@main
struct Operations_CenterApp: App {
    @State private var appState: AppState

    init() {
        // Check for --use-preview-data flag from Xcode scheme
        let usePreviewData = CommandLine.arguments.contains("--use-preview-data")

        _appState = State(initialValue: AppState(
            supabase: usePreviewData ? .preview : supabase,
            taskRepository: usePreviewData ? .preview : .live
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
