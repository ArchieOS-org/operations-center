//
//  InboxView.swift
//  Operations Center
//
//  Inbox view showing unclaimed tasks from all agents
//

import SwiftUI
import OperationsCenterKit

struct InboxView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView("Loading inbox...")
            } else if let error = appState.errorMessage {
                ErrorView(message: error) {
                    Task { await appState.refresh() }
                }
            } else if appState.inboxTasks.isEmpty {
                EmptyInboxView()
            } else {
                List(appState.inboxTasks) { task in
                    TaskRow(task: task)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                Task { await appState.claimTask(task) }
                            } label: {
                                Label("Claim", systemImage: "hand.raised")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await appState.deleteTask(task) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Inbox")
    }
}

struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No unclaimed tasks")
                .font(.headline)
            Text("New tasks will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        InboxView()
    }
}
