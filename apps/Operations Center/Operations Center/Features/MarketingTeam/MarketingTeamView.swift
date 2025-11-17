//
//  MarketingTeamView.swift
//  Operations Center
//
//  Marketing team view - uses generic TeamView
//

import SwiftUI
import OperationsCenterKit

struct MarketingTeamView: View {
    /// Store is @Observable - SwiftUI tracks changes automatically
    /// No @State wrapper needed for @Observable objects
    let store: MarketingTeamStore

    init(repository: TaskRepositoryClient) {
        self.store = MarketingTeamStore(taskRepository: repository)
    }

    var body: some View {
        TeamView(store: store, config: .marketing)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MarketingTeamView(repository: .preview)
    }
}
