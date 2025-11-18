//
//  MarketingTeamView.swift
//  Operations Center
//
//  Marketing team view - uses generic TeamView
//

import SwiftUI
import OperationsCenterKit

struct MarketingTeamView: View {
    @State private var store: MarketingTeamStore

    init(repository: TaskRepositoryClient) {
        _store = State(initialValue: MarketingTeamStore(taskRepository: repository))
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
