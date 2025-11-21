//
//  RootView.swift
//  Operations Center
//
//  Root navigation view with Things 3-style hierarchy
//

import SwiftUI
import SwiftData
import Supabase

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                // Primary sections (Things 3 style)
                Section {
                    NavigationLink(value: Route.inbox) {
                        Label("Inbox", systemImage: "tray.fill")
                    }
                    NavigationLink(value: Route.myTasks) {
                        Label("My Tasks", systemImage: "checkmark.circle.fill")
                    }
                    NavigationLink(value: Route.myListings) {
                        Label("My Listings", systemImage: "house.fill")
                    }
                    NavigationLink(value: Route.logbook) {
                        Label("Logbook", systemImage: "clock.fill")
                    }
                }

                // Browse sections
                Section("Browse") {
                    NavigationLink(value: Route.allTasks) {
                        Label("All Tasks", systemImage: "list.bullet")
                    }
                    NavigationLink(value: Route.allListings) {
                        Label("All Listings", systemImage: "building.2")
                    }
                    NavigationLink(value: Route.agents) {
                        Label("Agents", systemImage: "person.2.fill")
                    }
                }

                // Settings section
                Section {
                    NavigationLink(value: Route.settings) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("Operations Center")
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
            .task {
                // Skip startup in preview mode - zero network calls
                guard !CommandLine.arguments.contains("--use-preview-data") else { return }

                // Phase 1: Fast startup - load cached data and connect Realtime
                await appState.startup()
                await appState.connectRealtimeIfNeeded()

                // Phase 2: Background full sync - doesn't block UI
                // Runs in parallel with user interaction
                Task.detached { @MainActor in
                    do {
                        try await BackgroundSyncManager.shared.performFullSync()
                    } catch {
                        print("⚠️ [RootView] Background full sync failed: \(error)")
                    }
                }

                // Schedule background refresh (iOS will decide when to run)
                BackgroundSyncManager.shared.scheduleAppRefresh()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Skip lifecycle management in preview mode
                guard !CommandLine.arguments.contains("--use-preview-data") else { return }

                Task {
                    switch newPhase {
                    case .active:
                        // App came to foreground - reconnect Realtime
                        await appState.connectRealtimeIfNeeded()

                        // Run full sync in background (doesn't block UI)
                        Task.detached { @MainActor in
                            do {
                                try await BackgroundSyncManager.shared.performFullSync()
                            } catch {
                                print("⚠️ [RootView] Foreground full sync failed: \(error)")
                            }
                        }

                    case .inactive, .background:
                        // App going to background - disconnect Realtime to save battery
                        appState.disconnectRealtime()
                    @unknown default:
                        break
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        let usePreviewData = CommandLine.arguments.contains("--use-preview-data")

        // DRY up repository selection - extract constants to avoid repetition
        let localDB: LocalDatabase = usePreviewData ? PreviewLocalDatabase() : SwiftDataLocalDatabase(context: modelContext)
        let taskRepo: TaskRepositoryClient = usePreviewData ? .preview : .live(localDatabase: localDB)
        let listingRepo: ListingRepositoryClient = usePreviewData ? .preview : .live(localDatabase: localDB)
        let realtorRepo: RealtorRepositoryClient = usePreviewData ? .preview : .live
        let noteRepo: ListingNoteRepositoryClient = usePreviewData ? .preview : .live(localDatabase: localDB)
        // Global supabase returns stub in preview mode (--use-preview-data flag)
        let supabaseClient: SupabaseClient = supabase

        switch route {
        case .inbox:
            InboxView(store: InboxStore(
                taskRepository: taskRepo,
                listingRepository: listingRepo,
                noteRepository: noteRepo,
                realtorRepository: realtorRepo,
                supabase: supabaseClient,
                activityCoalescer: appState.activityCoalescer,
                noteCoalescer: appState.noteCoalescer
            ))
        case .myTasks:
            MyTasksView(
                repository: taskRepo,
                supabase: supabaseClient,
                taskCoalescer: appState.taskCoalescer
            )
        case .myListings:
            MyListingsView(
                listingRepository: listingRepo,
                taskRepository: taskRepo,
                supabase: supabaseClient,
                listingCoalescer: appState.listingCoalescer
            )
        case .logbook:
            LogbookView(
                listingRepository: listingRepo,
                taskRepository: taskRepo
            )
        case .agents:
            AgentsView(repository: realtorRepo, supabase: supabaseClient)
        case .agent(let id):
            AgentDetailView(
                realtorId: id,
                realtorRepository: realtorRepo,
                taskRepository: taskRepo,
                supabase: supabaseClient
            )
        case .listing(let id):
            ListingDetailView(
                listingId: id,
                listingRepository: listingRepo,
                noteRepository: noteRepo,
                taskRepository: taskRepo,
                realtorRepository: realtorRepo,
                supabase: supabaseClient,
                activityCoalescer: appState.activityCoalescer,
                noteCoalescer: appState.noteCoalescer
            )
        case .allTasks:
            AllTasksView(
                repository: taskRepo,
                supabase: supabaseClient,
                taskCoalescer: appState.taskCoalescer,
                activityCoalescer: appState.activityCoalescer
            )
        case .allListings:
            AllListingsView(
                listingRepository: listingRepo,
                taskRepository: taskRepo,
                supabase: supabaseClient,
                listingCoalescer: appState.listingCoalescer,
                activityCoalescer: appState.activityCoalescer
            )
        case .settings:
            SettingsView()
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
    }
}

#Preview {
    RootView()
        .environment(AppState(
            supabase: supabase,
            taskRepository: .preview,
            localDatabase: PreviewLocalDatabase()
        ))
        .modelContainer(for: [ListingEntity.self, ActivityEntity.self, ListingNoteEntity.self])
}
