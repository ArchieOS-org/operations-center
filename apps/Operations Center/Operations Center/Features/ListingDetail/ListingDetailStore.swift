//
//  ListingDetailStore.swift
//  Operations Center
//
//  Listing Detail screen store - manages listing data, notes, activities
//  Per TASK_MANAGEMENT_SPEC.md lines 338-375
//

import Dependencies
import Foundation
import OperationsCenterKit
import OSLog
import SwiftUI
import Supabase

/// Store for Listing Detail screen - see and claim activities within a listing
/// Per spec: "Purpose: See and claim Activities within a Listing"
@Observable
@MainActor
final class ListingDetailStore {
    // MARK: - Properties

    /// The listing being displayed
    private(set) var listing: Listing?

    /// Notes for this listing
    private(set) var notes: [ListingNote] = [] {
        didSet {
            updateSortedNotes()
        }
    }

    /// Notes sorted chronologically (oldest at top, newest at bottom)
    /// Cached to prevent recomputation during every layout pass
    private(set) var sortedNotes: [ListingNote] = []

    /// Activities for this listing
    private(set) var activities: [Activity] = []

    /// Realtor for this listing (if available)
    private(set) var realtor: Realtor?

    /// Expanded activity ID for UI state
    var expandedActivityId: String?

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Note input text - managed by view via binding
    var noteInputText = ""

    /// Pending note IDs for optimistic updates
    private var pendingNoteIds = Set<String>()

    /// Repositories for data access
    private let listingId: String
    private let listingRepository: ListingRepositoryClient
    private let noteRepository: ListingNoteRepositoryClient
    private let taskRepository: TaskRepositoryClient
    private let realtorRepository: RealtorRepositoryClient

    /// Coalescers for request deduplication
    private let activityCoalescer: ActivityFetchCoalescer
    private let noteCoalescer: NoteFetchCoalescer

    /// Supabase client for realtime subscriptions
    @ObservationIgnored
    private let supabase: SupabaseClient

    /// Realtime channels (stored to prevent "postgresChange after joining" error)
    @ObservationIgnored
    private var notesChannel: RealtimeChannelV2?

    @ObservationIgnored
    private var activitiesChannel: RealtimeChannelV2?

    /// Realtime subscription tasks
    @ObservationIgnored
    private var notesRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var activitiesRealtimeTask: Task<Void, Never>?

    /// Track note IDs for deduplication (optimistic updates + realtime)
    private var noteIds: Set<String> = []

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    init(
        listingId: String,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        taskRepository: TaskRepositoryClient,
        realtorRepository: RealtorRepositoryClient,
        supabase: SupabaseClient,
        activityCoalescer: ActivityFetchCoalescer,
        noteCoalescer: NoteFetchCoalescer
    ) {
        self.listingId = listingId
        self.listingRepository = listingRepository
        self.noteRepository = noteRepository
        self.taskRepository = taskRepository
        self.realtorRepository = realtorRepository
        self.supabase = supabase
        self.activityCoalescer = activityCoalescer
        self.noteCoalescer = noteCoalescer
    }

    deinit {
        Task.detached { [weak self] in
            guard let self else { return }
            await notesChannel?.unsubscribe()
            await activitiesChannel?.unsubscribe()
        }
        notesRealtimeTask?.cancel()
        activitiesRealtimeTask?.cancel()
    }

    // MARK: - Preview Support

    /// Preview factory for SwiftUI previews
    @MainActor
    static func makePreview(
        listingId: String,
        supabase: SupabaseClient
    ) -> ListingDetailStore {
        ListingDetailStore(
            listingId: listingId,
            listingRepository: .preview,
            noteRepository: .preview,
            taskRepository: .preview,
            realtorRepository: .preview,
            supabase: supabase,
            activityCoalescer: ActivityFetchCoalescer(),
            noteCoalescer: NoteFetchCoalescer()
        )
    }

    // MARK: - Computed Properties

    /// Marketing activities, sorted with incomplete first
    var marketingActivities: [Activity] {
        activities
            .filter { $0.taskCategory == .marketing }
            .sorted { ($0.completedAt == nil) && ($1.completedAt != nil) }
    }

    /// Admin activities, sorted with incomplete first
    var adminActivities: [Activity] {
        activities
            .filter { $0.taskCategory == .admin }
            .sorted { ($0.completedAt == nil) && ($1.completedAt != nil) }
    }

    /// Other categorized activities, sorted with incomplete first
    var otherActivities: [Activity] {
        activities
            .filter { $0.taskCategory != .marketing && $0.taskCategory != .admin && $0.taskCategory != nil }
            .sorted { ($0.completedAt == nil) && ($1.completedAt != nil) }
    }

    /// Uncategorized activities, sorted with incomplete first
    var uncategorizedActivities: [Activity] {
        activities
            .filter { $0.taskCategory == nil }
            .sorted { ($0.completedAt == nil) && ($1.completedAt != nil) }
    }

    // MARK: - Actions

    /// Fetch listing data, activities, and notes
    func fetchListingData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch listing, activities, and notes in parallel
            async let listingFetch = listingRepository.fetchListing(listingId)
            async let activitiesFetch = activityCoalescer.fetch(using: taskRepository)
            async let notesFetch = noteCoalescer.fetch(listingId: listingId, using: noteRepository)

            let (fetchedListing, allActivities, fetchedNotes) = try await (listingFetch, activitiesFetch, notesFetch)

            listing = fetchedListing

            // Fetch realtor if the listing has a realtorId
            realtor = nil
            if let realtorId = fetchedListing?.realtorId {
                do {
                    realtor = try await realtorRepository.fetchRealtor(realtorId)
                } catch {
                    Logger.database.error(
                        "Failed to fetch realtor for listing \(self.listingId): \(error.localizedDescription)"
                    )
                }
            }
            // Filter activities to only those for this listing
            activities = allActivities.map { $0.task }.filter { $0.listingId == listingId }
            notes = fetchedNotes

            Logger.database.info(
                """
                Fetched listing \(self.listingId) with \(self.activities.count) activities \
                and \(self.notes.count) notes
                """
            )

            // Start realtime subscriptions AFTER initial load
            await setupNotesRealtime()
            await setupActivitiesRealtime()
        } catch {
            Logger.database.error("Failed to fetch listing data: \(error.localizedDescription)")
            errorMessage = "Failed to load listing: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await fetchListingData()
    }

    /// Submit note - optimistic update for instant UI feedback
    func submitNote() {
        let trimmed = noteInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Create optimistic note immediately
        let tempId = UUID().uuidString
        let optimisticNote = ListingNote(
            id: tempId,
            listingId: listingId,
            content: trimmed,
            type: .general,
            createdBy: "Creating...",
            createdByName: "You",
            createdAt: Date(),
            updatedAt: Date()
        )

        // Instant UI update
        notes.append(optimisticNote)
        pendingNoteIds.insert(tempId)
        noteIds.insert(tempId)  // Track temp ID for deduplication
        noteInputText = ""

        // Fire async network call
        Task {
            await createNoteInBackground(tempId: tempId, content: trimmed)
        }
    }

    /// Create note in background - replace optimistic version with server response
    private func createNoteInBackground(tempId: String, content: String) async {
        do {
            let createdNote = try await noteRepository.createNote(listingId, content)

            // Replace temp note with server response
            if let index = notes.firstIndex(where: { $0.id == tempId }) {
                notes[index] = createdNote

                // Update ID tracking for deduplication
                noteIds.remove(tempId)
                noteIds.insert(createdNote.id)
            }
            pendingNoteIds.remove(tempId)

            Logger.database.info("Created note for listing \(self.listingId)")
        } catch {
            // Revert optimistic update
            notes.removeAll { $0.id == tempId }
            noteIds.remove(tempId)  // Clean up temp ID
            pendingNoteIds.remove(tempId)

            Logger.database.error("Failed to create note: \(error.localizedDescription)")
            errorMessage = "Failed to create note: \(error.localizedDescription)"
        }
    }

    /// Delete a note
    func deleteNote(_ note: ListingNote) async {
        do {
            try await noteRepository.deleteNote(note.id)

            // Remove from local list
            notes.removeAll { $0.id == note.id }

            Logger.database.info("Deleted note \(note.id)")
        } catch {
            Logger.database.error("Failed to delete note: \(error.localizedDescription)")
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }
    }

    // MARK: - Activity Actions

    /// Toggle expansion state for an activity
    func toggleExpansion(for activityId: String) {
        if expandedActivityId == activityId {
            expandedActivityId = nil
        } else {
            expandedActivityId = activityId
        }
    }

    /// Claim an activity
    func claimActivity(_ activity: Activity) async {
        do {
            let userId = try await authClient.currentUserId()
            _ = try await taskRepository.claimActivity(activity.id, userId)
            await fetchListingData() // Refresh
        } catch {
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    /// Delete an activity
    func deleteActivity(_ activity: Activity) async {
        do {
            let userId = try await authClient.currentUserId()
            try await taskRepository.deleteActivity(activity.id, userId)
            await fetchListingData() // Refresh
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Update sorted notes cache
    /// Called automatically when notes array changes
    private func updateSortedNotes() {
        sortedNotes = notes.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Realtime Subscriptions

    /// Setup realtime subscription for notes on this listing
    private func setupNotesRealtime() async {
        notesRealtimeTask?.cancel()

        // Create channel once and store reference (prevents "postgresChange after joining" error)
        if notesChannel == nil {
            notesChannel = supabase.realtimeV2.channel("listing_\(listingId)_notes")
        }

        guard let channel = notesChannel else { return }

        notesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = channel.postgresChange(AnyAction.self, table: "listing_notes")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await channel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleNotesChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Notes realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime note changes - simple refresh strategy
    private func handleNotesChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Note change detected, refreshing...")

        // Simple approach: re-fetch all notes for this listing
        // AppState pattern - avoids complex decode logic
        do {
            let fetchedNotes = try await noteCoalescer.fetch(listingId: listingId, using: noteRepository)
            notes = fetchedNotes

            // Rebuild ID set for deduplication
            noteIds = Set(notes.map(\.id))

            Logger.database.info("Realtime: Refreshed \(self.notes.count) notes")
        } catch {
            Logger.database.error("Failed to refresh notes: \(error.localizedDescription)")
        }
    }

    /// Setup realtime subscription for activities on this listing
    private func setupActivitiesRealtime() async {
        activitiesRealtimeTask?.cancel()

        // Create channel once and store reference (prevents "postgresChange after joining" error)
        if activitiesChannel == nil {
            activitiesChannel = supabase.realtimeV2.channel("listing_\(listingId)_activities")
        }

        guard let channel = activitiesChannel else { return }

        activitiesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = channel.postgresChange(AnyAction.self, table: "activities")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await channel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleActivitiesChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Activities realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime activity changes - simple refresh strategy
    private func handleActivitiesChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Activity change detected, refreshing...")

        // Simple approach: re-fetch all activities for this listing
        do {
            let allActivities = try await activityCoalescer.fetch(using: taskRepository)
            activities = allActivities.map(\.task).filter { $0.listingId == listingId }

            Logger.database.info("Realtime: Refreshed \(self.activities.count) activities")
        } catch {
            Logger.database.error("Failed to refresh activities: \(error.localizedDescription)")
        }
    }
}

