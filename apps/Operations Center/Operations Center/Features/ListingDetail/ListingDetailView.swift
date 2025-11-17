//
//  ListingDetailView.swift
//  Operations Center
//
//  Listing Detail screen - see and claim activities within a listing
//  Per TASK_MANAGEMENT_SPEC.md lines 338-375
//

import SwiftUI
import OperationsCenterKit

/// Listing Detail screen - see and claim activities within a listing
/// Per spec: "Purpose: See and claim Activities within a Listing"
/// Features: Header with address, notes section, activities/tasks sections
struct ListingDetailView: View {
    // MARK: - Properties

    @State private var store: ListingDetailStore

    // MARK: - Initialization

    init(
        listingId: String,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient
    ) {
        _store = State(initialValue: ListingDetailStore(
            listingId: listingId,
            listingRepository: listingRepository,
            noteRepository: noteRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        List {
            notesSection
            placeholderSections
        }
        .listStyle(.plain)
        .navigationTitle(store.listing?.title ?? "Listing")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchListingData()
        }
        .loadingOverlay(store.isLoading && store.listing == nil)
        .errorAlert($store.errorMessage)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var notesSection: some View {
        Section {
            // Note input field
            // Per spec: "Click to add note. Type, press Enter to save" (lines 352-353)
            TextField("Add a note...", text: $store.newNoteText, axis: .vertical)
                .lineLimit(1...3)
                .onSubmit {
                    Task {
                        await store.createNote()
                    }
                }
                .submitLabel(.done)

            // Existing notes
            // Per spec: "Shows author name per note. Unlimited notes" (lines 354-355)
            if !store.notes.isEmpty {
                ForEach(store.notes) { note in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(note.content)
                            .font(.body)

                        HStack {
                            if let author = note.createdBy {
                                Text(author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(note.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await store.deleteNote(note)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } else {
                Text("No notes yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.sm)
            }
        } header: {
            Text("Notes")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var placeholderSections: some View {
        // Per spec lines 357-373: Activities and Tasks sections
        // Placeholder for future implementation

        Section {
            Text("Marketing Activities")
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } header: {
            Text("Marketing Activities")
                .font(.headline)
        }

        Section {
            Text("Admin Activities")
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } header: {
            Text("Admin Activities")
                .font(.headline)
        }

        Section {
            Text("Tasks")
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } header: {
            Text("Tasks")
                .font(.headline)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ListingDetailView(
            listingId: "listing_001",
            listingRepository: .preview,
            noteRepository: .preview
        )
    }
}
