//
//  TeamToggle.swift
//  OperationsCenterKit
//
//  Team filter toggle for Marketing/Admin/All
//  Per TASK_MANAGEMENT_SPEC.md lines 483-499
//

import SwiftUI

/// Team filter options
///
/// Per TASK_MANAGEMENT_SPEC.md:
/// - Present on: My Listings, All Tasks, All Listings (line 488)
/// - NOT present on: Inbox, My Tasks, Marketing Team View, Admin Team View, Agents (line 491)
public enum TeamFilter: String, CaseIterable, Identifiable {
    case marketing = "Marketing"
    case admin = "Admin"
    case all = "All"

    public var id: String { rawValue }
}

/// Team filter toggle (Marketing/Admin/All)
///
/// Per TASK_MANAGEMENT_SPEC.md line 486: "Location: Bottom left"
public struct TeamToggle: View {
    // MARK: - Properties

    @Binding private var selection: TeamFilter

    // MARK: - Initialization

    public init(selection: Binding<TeamFilter>) {
        self._selection = selection
    }

    // MARK: - Body

    public var body: some View {
        Picker("Team", selection: $selection) {
            ForEach(TeamFilter.allCases) { filter in
                Text(filter.rawValue)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
    }
}

// MARK: - View Extension

public extension View {
    /// Adds a team filter toggle overlay to the view
    /// Positioned at bottom leading with padding
    ///
    /// Per TASK_MANAGEMENT_SPEC.md: "Location: Bottom left" (line 486)
    ///
    /// - Parameter selection: Binding to current team filter
    func teamToggle(selection: Binding<TeamFilter>) -> some View {
        overlay(alignment: .bottomLeading) {
            TeamToggle(selection: selection)
                .padding(Spacing.lg)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selection: TeamFilter = .all

    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Text("Screen Content")
                .font(.title)

            Text("Selected: \(selection.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .teamToggle(selection: $selection)
}
