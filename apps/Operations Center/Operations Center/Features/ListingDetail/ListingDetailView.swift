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
        noteRepository: ListingNoteRepositoryClient,
        taskRepository: TaskRepositoryClient
    ) {
        _store = State(initialValue: ListingDetailStore(
            listingId: listingId,
            listingRepository: listingRepository,
            noteRepository: noteRepository,
            taskRepository: taskRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md, pinnedViews: [.sectionHeaders]) {
                notesSection

                // Marketing Activities Section
                if !store.marketingActivities.isEmpty {
                    Section {
                        ForEach(store.marketingActivities) { activity in
                            activityCard(activity)
                        }
                    } header: {
                        sectionHeader(title: "Marketing Activities", count: store.marketingActivities.count)
                    }
                }

                // Admin Activities Section
                if !store.adminActivities.isEmpty {
                    Section {
                        ForEach(store.adminActivities) { activity in
                            activityCard(activity)
                        }
                    } header: {
                        sectionHeader(title: "Admin Activities", count: store.adminActivities.count)
                    }
                }

                // Other Activities Section
                if !store.otherActivities.isEmpty {
                    Section {
                        ForEach(store.otherActivities) { activity in
                            activityCard(activity)
                        }
                    } header: {
                        sectionHeader(title: "Other Activities", count: store.otherActivities.count)
                    }
                }

                // Uncategorized Activities Section
                if !store.uncategorizedActivities.isEmpty {
                    Section {
                        ForEach(store.uncategorizedActivities) { activity in
                            activityCard(activity)
                        }
                    } header: {
                        sectionHeader(title: "Uncategorized", count: store.uncategorizedActivities.count)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(store.listing?.title ?? "Listing")
        .refreshable {
            await store.refresh()
        }
        .task {
            await store.fetchListingData()
        }
        .loadingOverlay(store.isLoading && store.listing == nil)
        .errorAlert($store.errorMessage)
        .overlay(alignment: .bottom) {
            // Floating action bar when activity is expanded
            if let expandedId = store.expandedActivityId,
               let activity = findExpandedActivity(id: expandedId) {
                DSContextMenu(actions: buildActivityActions(for: activity))
                    .padding(.bottom, Spacing.lg)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: store.expandedActivityId)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var notesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Note input field
                TextField("Add a note...", text: $store.newNoteText, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await store.createNote()
                        }
                    }
                    .submitLabel(.done)

                // Existing notes
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

                                Spacer()

                                Button(role: .destructive) {
                                    Task {
                                        await store.deleteNote(note)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, Spacing.xs)

                        if note.id != store.notes.last?.id {
                            Divider()
                        }
                    }
                } else {
                    Text("No notes yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.sm)
                }
            }
        } header: {
            sectionHeader(title: "Notes", count: store.notes.count)
        }
    }

    @ViewBuilder
    private func activityCard(_ activity: Activity) -> some View {
        if let listing = store.listing {
            ActivityCard(
                task: activity,
                listing: listing,
                isExpanded: store.expandedActivityId == activity.id,
                onTap: {
                    withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                        store.toggleExpansion(for: activity.id)
                    }
                }
            )
            .strikethrough(activity.completedAt != nil)
            .opacity(activity.completedAt != nil ? 0.6 : 1.0)
            .id(activity.id)
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.vertical, Spacing.sm)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Helper Methods

    private func findExpandedActivity(id: String) -> Activity? {
        store.activities.first(where: { $0.id == id })
    }

    private func buildActivityActions(for activity: Activity) -> [DSContextAction] {
        DSContextAction.standardTaskActions(
            onClaim: {
                Task { await store.claimActivity(activity) }
            },
            onDelete: {
                Task { await store.deleteActivity(activity) }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ListingDetailView(
            listingId: "listing_001",
            listingRepository: .preview,
            noteRepository: .preview,
            taskRepository: .preview
        )
    }
}
