//
//  OCEmptyState.swift
//  OperationsCenterKit
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Lightweight empty-state view for list screens
public struct OCEmptyState: View {
    private let title: String
    private let systemImage: String
    private let description: String?
    private let searchText: String?
    private let action: (() -> Void)?
    private let actionLabel: String?

    /// Initialize with title, image, and optional description
    public init(
        title: String,
        systemImage: String,
        description: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.searchText = nil
        self.action = action
        self.actionLabel = actionLabel
    }

    /// Initialize for search results empty state
    public init(searchText: String) {
        self.title = "No Results"
        self.systemImage = "magnifyingglass"
        self.description = "No results found for \"\(searchText)\""
        self.searchText = searchText
        self.action = nil
        self.actionLabel = nil
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let description {
                Text(description)
                    .foregroundStyle(Color.secondary)
            }
        } actions: {
            if let action, let actionLabel {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Common Empty States

extension OCEmptyState {
    /// Empty listings state
    public static var noListings: OCEmptyState {
        OCEmptyState(
            title: "No Listings",
            systemImage: "house",
            description: "New listings will appear here"
        )
    }

    /// Empty tasks state
    public static var noTasks: OCEmptyState {
        OCEmptyState(
            title: "No Tasks",
            systemImage: "checkmark.circle",
            description: "You're all caught up!"
        )
    }

    /// Empty agents state
    public static var noAgents: OCEmptyState {
        OCEmptyState(
            title: "No Agents",
            systemImage: "person.3",
            description: "Add agents to see them here"
        )
    }

    /// Empty inbox state
    public static var inboxEmpty: OCEmptyState {
        OCEmptyState(
            title: "Inbox Zero",
            systemImage: "tray",
            description: "You're all caught up! New items will appear here."
        )
    }

    /// Empty logbook state
    public static var noActivity: OCEmptyState {
        OCEmptyState(
            title: "No Activity",
            systemImage: "clock",
            description: "Activity history will appear here"
        )
    }

    /// Network error state with retry action
    public static func networkError(retry: @escaping () -> Void) -> OCEmptyState {
        OCEmptyState(
            title: "Connection Error",
            systemImage: "wifi.slash",
            description: "Check your internet connection and try again",
            action: retry,
            actionLabel: "Retry"
        )
    }

    /// General error state with retry action
    public static func loadingError(retry: @escaping () -> Void) -> OCEmptyState {
        OCEmptyState(
            title: "Something Went Wrong",
            systemImage: "exclamationmark.triangle",
            description: "We couldn't load this content",
            action: retry,
            actionLabel: "Try Again"
        )
    }
}