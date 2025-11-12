//
//  ContentView.swift
//  Operations Center
//
//  Main view - displays listing tasks from Supabase
//

import SwiftUI
import OperationsCenterKit

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView("Loading tasks...")
            } else if let error = appState.errorMessage {
                ErrorView(message: error) {
                    Task { await appState.refresh() }
                }
            } else if appState.allTasks.isEmpty {
                EmptyStateView()
            } else {
                List(appState.allTasks) { task in
                    TaskRow(task: task)
                }
            }
        }
        .navigationTitle("All Tasks")
    }
}

struct TaskRow: View {
    let task: ListingTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: task.status)
            }

            if let description = task.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                CategoryBadge(category: task.taskCategory)

                if task.priority > 0 {
                    PriorityBadge(priority: task.priority)
                }

                Spacer()

                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: ListingTask.TaskStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(.white)
    }

    private var backgroundColor: Color {
        switch status {
        case .open: return .blue
        case .claimed: return .cyan
        case .inProgress: return .orange
        case .done: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

struct CategoryBadge: View {
    let category: ListingTask.TaskCategory

    var body: some View {
        Label(category.rawValue, systemImage: icon)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var icon: String {
        switch category {
        case .admin: return "doc.text"
        case .marketing: return "megaphone"
        case .photo: return "camera"
        case .staging: return "house"
        case .inspection: return "magnifyingglass"
        case .other: return "ellipsis.circle"
        }
    }
}

struct PriorityBadge: View {
    let priority: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.circle.fill")
            Text("P\(priority)")
        }
        .font(.caption)
        .foregroundStyle(priority >= 7 ? .red : .orange)
    }
}

// MARK: - Supporting Views

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Error loading tasks")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No tasks yet")
                .font(.headline)
            Text("Tasks will appear here when created")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
