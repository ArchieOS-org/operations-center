//
//  AdminTeamView.swift
//  Operations Center
//
//  Admin team view - uses generic TeamView
//

import SwiftUI
import OperationsCenterKit

struct AdminTeamView: View {
    /// Store is @Observable - SwiftUI tracks changes automatically
    /// No @State wrapper needed for @Observable objects
    let store: AdminTeamStore

    init(repository: TaskRepositoryClient) {
        self.store = AdminTeamStore(taskRepository: repository)
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
