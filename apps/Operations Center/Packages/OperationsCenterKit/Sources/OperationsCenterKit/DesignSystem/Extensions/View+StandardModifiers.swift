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
    /// ```
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
    /// ```
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
    /// ```
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
    /// ```
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
    /// ```
    func bottomLeadingOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        overlay(alignment: .bottomLeading) {
            content()
                .padding(.leading, Spacing.screenEdge)
                .padding(.bottom, Spacing.screenEdge)
        }
    }
}
