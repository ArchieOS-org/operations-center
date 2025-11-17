//
//  MetadataItem.swift
//  OperationsCenterKit
//
//  Displays a labeled metadata field (label + value)
//  Used in expanded card views for dates, status, categories, etc.
//

import SwiftUI

public struct MetadataItem: View {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            Text(value)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Metadata Grid

/// Grid layout for multiple metadata items
public struct MetadataGrid<Content: View>: View {
    private let columns: [GridItem]
    private let content: Content

    public init(
        columnCount: Int = 2,
        spacing: CGFloat = Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columnCount
        )
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
            content
        }
    }
}

// MARK: - Metadata Section

/// Section wrapper for metadata with optional header
public struct MetadataSection<Content: View>: View {
    private let title: String?
    private let content: Content

    public init(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            content
        }
    }
}

// MARK: - Preview

#Preview("Single Item") {
    MetadataItem(label: "Created", value: "Nov 16, 2024")
        .padding()
}

#Preview("Grid") {
    MetadataGrid {
        MetadataItem(label: "Created", value: "Nov 16, 2024")
        MetadataItem(label: "Due Date", value: "Nov 20, 2024")
        MetadataItem(label: "Status", value: "In Progress")
        MetadataItem(label: "Category", value: "Marketing")
    }
    .padding()
}

#Preview("Section") {
    MetadataSection(title: "Task Details") {
        MetadataGrid {
            MetadataItem(label: "Created", value: "Nov 16, 2024")
            MetadataItem(label: "Due Date", value: "Nov 20, 2024")
            MetadataItem(label: "Status", value: "In Progress")
            MetadataItem(label: "Category", value: "Marketing")
        }
    }
    .padding()
}
