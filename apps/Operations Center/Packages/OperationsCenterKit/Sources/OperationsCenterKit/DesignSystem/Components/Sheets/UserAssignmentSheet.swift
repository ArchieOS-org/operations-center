//
//  UserAssignmentSheet.swift
//  OperationsCenterKit
//
//  Sheet for assigning tasks/activities to team members
//  Clean, searchable, accessible user picker
//

import SwiftUI

public struct UserAssignmentSheet: View {
    @Binding public var selectedStaff: Staff?
    public let availableStaff: [Staff]
    public let onConfirm: (Staff) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    public init(
        selectedStaff: Binding<Staff?>,
        availableStaff: [Staff],
        onConfirm: @escaping (Staff) -> Void
    ) {
        self._selectedStaff = selectedStaff
        self.availableStaff = availableStaff
        self.onConfirm = onConfirm
    }

    private var filteredStaff: [Staff] {
        guard !searchText.isEmpty else {
            return availableStaff.filter { $0.isActive }
        }

        return availableStaff
            .filter { $0.isActive }
            .filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
    }

    public var body: some View {
        NavigationStack {
            List(filteredStaff) { staff in
                StaffRow(staff: staff, isSelected: selectedStaff?.id == staff.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStaff = staff
                    }
                    .lightFeedback(trigger: selectedStaff?.id)
            }
            .searchable(text: $searchText, prompt: "Search team members")
            .navigationTitle("Assign To")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        if let staff = selectedStaff {
                            onConfirm(staff)
                            dismiss()
                        }
                    }
                    .disabled(selectedStaff == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Staff Row

private struct StaffRow: View {
    let staff: Staff
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar with initials
            Circle()
                .fill(Colors.accentPrimary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(staff.initials)
                        .font(.headline)
                        .foregroundStyle(Colors.accentPrimary)
                }

            // Staff info
            VStack(alignment: .leading, spacing: 2) {
                Text(staff.name)
                    .font(.headline)

                Text(staff.role.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Colors.accentPrimary)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Staff Extensions

extension Staff {
    /// Get user initials from name
    public var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

extension Staff.StaffRole {
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .manager:
            return "Manager"
        case .staff:
            return "Staff"
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedStaff: Staff?
        @State private var showingSheet = true

        let mockStaff = [
            Staff(
                id: "1",
                name: "John Smith",
                email: "john@example.com",
                phone: nil,
                role: .admin,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Staff(
                id: "2",
                name: "Jane Doe",
                email: "jane@example.com",
                phone: nil,
                role: .manager,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Staff(
                id: "3",
                name: "Bob Johnson",
                email: "bob@example.com",
                phone: nil,
                role: .staff,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]

        var body: some View {
            Button("Show Assignment Sheet") {
                showingSheet = true
            }
            .sheet(isPresented: $showingSheet) {
                UserAssignmentSheet(
                    selectedStaff: $selectedStaff,
                    availableStaff: mockStaff,
                    onConfirm: { staff in
                        print("Assigned to: \(staff.name)")
                    }
                )
            }
        }
    }

    return PreviewWrapper()
}
