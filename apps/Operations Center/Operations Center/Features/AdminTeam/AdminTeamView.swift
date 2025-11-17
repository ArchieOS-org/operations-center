//
//  AdminTeamView.swift
//  Operations Center
//
//  Admin team view - uses generic TeamView
//

import SwiftUI
import OperationsCenterKit

struct AdminTeamView: View {
    @State private var store: AdminTeamStore

    init(repository: TaskRepositoryClient) {
        _store = State(initialValue: AdminTeamStore(taskRepository: repository))
    }

    var body: some View {
        TeamView(store: store, config: .admin)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminTeamView(repository: .preview)
    }
}
