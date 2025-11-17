//
//  CategoryFilterPicker.swift
//  Operations Center
//
//  Reusable category filter picker component
//  Eliminates duplication across AllListingsView and MyListingsView
//

import SwiftUI
import OperationsCenterKit

/// Category filter picker for listing views
/// Displays segmented control for All/Admin/Marketing
struct CategoryFilterPicker: View {
    // MARK: - Properties

    @Binding var selection: TaskCategory?

    // MARK: - Body

    var body: some View {
        Section {
            Picker("Category", selection: $selection) {
                Text("All").tag(nil as TaskCategory?)
                Text("Admin").tag(TaskCategory.admin as TaskCategory?)
                Text("Marketing").tag(TaskCategory.marketing as TaskCategory?)
            }
            .pickerStyle(.segmented)
            .fixedSize(horizontal: false, vertical: true)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        CategoryFilterPicker(selection: .constant(nil))
    }
}
