//
//  OperationsCenterApp.swift
//  Operations Center
//
//  Created by Noah Deskin on 2025-11-11.
//

import OperationsCenterKit
import SwiftUI
import SwiftData

@MainActor
@main
struct OperationsCenterApp: App {
    @State private var appState: AppState

    // SwiftData ModelContainer for offline-first persistence
    let modelContainer: ModelContainer

    init() {
        // Check for --use-preview-data flag from Xcode scheme
        let usePreviewData = CommandLine.arguments.contains("--use-preview-data")

        // Clear cached data in preview mode (legacy UserDefaults)
        if usePreviewData {
            UserDefaults.standard.removeObject(forKey: "cached_tasks")
        }

        // Create ModelContainer with proper directory setup
        // Uses explicit Application Support path to avoid "Failed to create file" errors
        do {
            modelContainer = try ModelContainer.operationsCenterContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Create LocalDatabase from ModelContainer
        let localDatabase: LocalDatabase
        if usePreviewData {
            localDatabase = PreviewLocalDatabase()
        } else {
            let context = ModelContext(modelContainer)
            localDatabase = SwiftDataLocalDatabase(context: context)
        }

        // Initialize repository clients with local database
        let taskRepository = usePreviewData
            ? TaskRepositoryClient.preview
            : TaskRepositoryClient.live(localDatabase: localDatabase)

        _ = usePreviewData
            ? ListingRepositoryClient.preview
            : ListingRepositoryClient.live(localDatabase: localDatabase)

        _ = usePreviewData
            ? ListingNoteRepositoryClient.preview
            : ListingNoteRepositoryClient.live(localDatabase: localDatabase)

        // Initialize AppState with local database
        let appState = AppState(
            supabase: supabase,
            taskRepository: taskRepository,
            localDatabase: localDatabase
        )

        // Pre-populate with mock data in preview mode
        if usePreviewData {
            appState.allTasks = [.mock1, .mock2, .mock3]
        }

        _appState = State(initialValue: appState)
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
        .modelContainer(modelContainer)
    }
}
