//
//  RootView.swift
//  Operations Center
//
//  Root navigation view with Things 3-style hierarchy
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
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
        }
        .task {
            // Start async operations after app launches
            await appState.startup()
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .inbox:
            InboxView()
        case .myTasks:
            PlaceholderView(title: "My Tasks", icon: "checkmark.circle.fill")
        case .myListings:
            PlaceholderView(title: "My Listings", icon: "house.fill")
        case .logbook:
            PlaceholderView(title: "Logbook", icon: "clock.fill")
        case .agent(let id):
            PlaceholderView(title: "Agent", icon: "person.fill", subtitle: id)
        case .listing(let id):
            PlaceholderView(title: "Listing", icon: "building.2.fill", subtitle: id)
        case .allTasks:
            ContentView()
        case .allListings:
            PlaceholderView(title: "All Listings", icon: "building.2")
        case .settings:
            SettingsView()
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String
    var subtitle: String? = nil

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
            supabase: .preview,
            taskRepository: .preview
        ))
}
