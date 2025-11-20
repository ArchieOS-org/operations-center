//
//  OperationsCenterApp.swift
//  Operations Center
//
//  Created by Noah Deskin on 2025-11-11.
//

import BackgroundTasks
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

        let listingRepository = usePreviewData
            ? ListingRepositoryClient.preview
            : ListingRepositoryClient.live(localDatabase: localDatabase)

        let noteRepository = usePreviewData
            ? ListingNoteRepositoryClient.preview
            : ListingNoteRepositoryClient.live(localDatabase: localDatabase)

        let realtorRepository = usePreviewData
            ? RealtorRepositoryClient.preview
            : RealtorRepositoryClient.live

        let staffRepository = usePreviewData
            ? StaffRepositoryClient.testValue
            : StaffRepositoryClient.liveValue

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

        // Register and wire background sync (production only)
        if !usePreviewData {
            registerBackgroundTasks()
            wireBackgroundSyncDependencies(
                localDatabase: localDatabase,
                listingRepository: listingRepository,
                taskRepository: taskRepository,
                noteRepository: noteRepository,
                realtorRepository: realtorRepository,
                staffRepository: staffRepository
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Background Tasks

    /// Register BGAppRefreshTask handler
    ///
    /// Must complete before applicationDidFinishLaunching(_:) returns.
    /// Returns false if identifier not in Info.plist BGTaskSchedulerPermittedIdentifiers.
    private nonisolated func registerBackgroundTasks() {
        let taskIdentifier = BackgroundSyncManager.refreshTaskIdentifier
        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil // Uses default background queue
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                BackgroundSyncManager.shared.handleAppRefresh(task: refreshTask)
            }
        }

        if registered {
            print("✅ [BackgroundTasks] Registered: \(taskIdentifier)")
        } else {
            print("❌ [BackgroundTasks] Failed to register - check Info.plist BGTaskSchedulerPermittedIdentifiers")
        }
    }

    /// Wire dependencies into BackgroundSyncManager
    private func wireBackgroundSyncDependencies(
        localDatabase: LocalDatabase,
        listingRepository: ListingRepositoryClient,
        taskRepository: TaskRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        realtorRepository: RealtorRepositoryClient,
        staffRepository: StaffRepositoryClient
    ) {
        BackgroundSyncManager.shared.localDatabase = localDatabase
        BackgroundSyncManager.shared.listingRepository = listingRepository
        BackgroundSyncManager.shared.taskRepository = taskRepository
        BackgroundSyncManager.shared.noteRepository = noteRepository
        BackgroundSyncManager.shared.realtorRepository = realtorRepository
        BackgroundSyncManager.shared.staffRepository = staffRepository

        print("✅ [BackgroundSync] Dependencies wired (including realtors and staff)")
    }

    /// Schedule background app refresh
    ///
    /// Called once at app launch after setup completes.
    /// BackgroundSyncManager reschedules itself after each execution.
    func scheduleInitialBackgroundRefresh() {
        BackgroundSyncManager.shared.scheduleAppRefresh()
    }
}
