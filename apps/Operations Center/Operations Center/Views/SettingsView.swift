//
//  SettingsView.swift
//  Operations Center
//
//  Settings screen
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            } header: {
                Text("About")
            }

            Section {
                Link(destination: URL(string: "https://conductor.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://conductor.app/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://conductor.app/support")!) {
                    HStack {
                        Text("Support")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
