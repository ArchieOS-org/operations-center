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

        // Clear cached data in preview mode
        if usePreviewData {
            UserDefaults.standard.removeObject(forKey: "cached_tasks")
        }

        let appState = AppState(
            supabase: supabase,  // Always real client
            taskRepository: usePreviewData ? .preview : .live
        )

        // Pre-populate with mock data in preview mode
        if usePreviewData {
            appState.allTasks = [.mock1, .mock2, .mock3]
        }

        _appState = State(initialValue: appState)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
