import SwiftUI

/// Standard view modifiers for eliminating boilerplate
///
/// Design Philosophy:
/// - One way to do common things
/// - Eliminates copy-paste patterns
/// - Consistent behavior across the app
///
/// Based on SwiftUI best practices from Context7

// MARK: - Error Handling

public extension View {
    /// Standard error alert that appears when errorMessage is not nil
    ///
    /// Usage:
    /// ```swift
    /// .errorAlert($store.errorMessage)
    /// Presents an alert titled "Error" when the provided binding contains a message.
    /// The alert displays the message and clears the binding when dismissed or when the "OK" button is tapped.
    /// - Parameter errorMessage: A binding to an optional `String` containing the error message; the alert is shown while this value is non-nil and the value is set to `nil` on dismissal.
    /// - Returns: A view that presents the error alert when `errorMessage` is non-nil.
    func errorAlert(_ errorMessage: Binding<String?>) -> some View {
        alert("Error", isPresented: Binding(
            get: { errorMessage.wrappedValue != nil },
            set: { if !$0 { errorMessage.wrappedValue = nil } }
        )) {
            Button("OK") {
                errorMessage.wrappedValue = nil
            }
        } message: {
            if let error = errorMessage.wrappedValue {
                Text(error)
            }
        }
    }
}

// MARK: - List Configuration

public extension View {
    /// Standard list configuration with title, refresh, and task
    ///
    /// Usage:
    /// ```swift
    /// List { }
    ///     .standardList(
    ///         title: "All Listings",
    ///         onRefresh: { await store.refresh() },
    ///         onAppear: { await store.fetchAllListings() }
    ///     )
    /// Configures the view as a standardized list with a navigation title, pull-to-refresh, and an on-appear task.
    /// - Parameters:
    ///   - title: The navigation title displayed for the list.
    ///   - onRefresh: An asynchronous task invoked when the user performs pull-to-refresh.
    ///   - onAppear: An asynchronous task run when the view appears.
    /// - Returns: A view configured with plain list style, the provided navigation title, pull-to-refresh that calls `onRefresh`, and a task that runs `onAppear` when the view appears.
    func standardList(
        title: String,
        onRefresh: @escaping () async -> Void,
        onAppear: @escaping () async -> Void
    ) -> some View {
        self
            .listStyle(.plain)
            .navigationTitle(title)
            .refreshable { await onRefresh() }
            .task { await onAppear() }
    }

    /// Standard list row insets for card-style rows
    ///
    /// Usage:
    /// ```swift
    /// NavigationLink { }
    ///     .standardListRowInsets()
    /// Applies card-style insets to list rows and hides the row separator.
    /// - Returns: A view that uses `.listRowInsets(.listCardInsets)` and `.listRowSeparator(.hidden)`.
    func standardListRowInsets() -> some View {
        self
            .listRowInsets(.listCardInsets)
            .listRowSeparator(.hidden)
    }
}

// MARK: - Context Menu Overlay

public extension View {
    /// Floating context menu overlay with animation
    ///
    /// Usage:
    /// ```swift
    /// .floatingContextMenu(
    ///     expandedId: store.expandedTaskId,
    ///     items: store.tasks,
    ///     keyPath: \.id,
    ///     buildActions: buildTaskActions
    /// )
    /// Displays a bottom-aligned context menu for the item whose identifier matches `expandedId`.
    /// - Parameters:
    ///   - expandedId: The identifier of the item to expand; when `nil` no menu is shown.
    ///   - items: The collection of items to search for a matching identifier.
    ///   - keyPath: A key path to the item's identifier string.
    ///   - buildActions: A closure that produces the `DSContextAction` list for the matched item.
    /// - Returns: A view that overlays a `DSContextMenu` at the bottom when an item with `keyPath == expandedId` is found; the menu includes horizontal and bottom padding, uses a bottom move + opacity transition, and animates when `expandedId` changes.
    func floatingContextMenu<T>(
        expandedId: String?,
        items: [T],
        keyPath: KeyPath<T, String>,
        buildActions: @escaping (T) -> [DSContextAction]
    ) -> some View {
        overlay(alignment: .bottom) {
            if let id = expandedId,
               let item = items.first(where: { $0[keyPath: keyPath] == id }) {
                DSContextMenu(actions: buildActions(item))
                    .padding(.bottom, Spacing.lg)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Animations.cardExpansion, value: expandedId)
    }
}

// MARK: - Bottom Overlay

public extension View {
    /// Bottom-leading overlay for controls (like team toggle)
    ///
    /// Usage:
    /// ```swift
    /// .bottomLeadingOverlay {
    ///     TeamToggle(selection: $store.teamFilter)
    /// }
    /// Places the provided content as an overlay aligned to the bottom-leading edge with standard screen-edge padding.
    /// - Parameters:
    ///   - content: A view builder that produces the overlay content.
    /// - Returns: A view with the supplied content overlaid at the bottom-leading edge, padded from the screen edges.
    func bottomLeadingOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        overlay(alignment: .bottomLeading) {
            content()
                .padding(.leading, Spacing.screenEdge)
                .padding(.bottom, Spacing.screenEdge)
        }
    }
}