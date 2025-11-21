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
    let listingId: String  // Exposed for view logging
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

    /// Track if Realtime is set up to prevent duplicate subscriptions
    private var didSetupRealtime = false

    /// Debounce tasks for Realtime refetches (prevent refetch storms)
    @ObservationIgnored
    private var notesRefetchTask: Task<Void, Never>?

    @ObservationIgnored
    private var activitiesRefetchTask: Task<Void, Never>?

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
        Logger.database.info("🧠 [ListingDetailStore] init for listing \(listingId)")
    }

    deinit {
        let listingIdCopy = listingId  // Capture for async logging
        Logger.database.info("💀 [ListingDetailStore] deinit for listing \(listingIdCopy) - cancelling tasks")

        // Cancel tasks first to stop stream loops
        notesRealtimeTask?.cancel()
        activitiesRealtimeTask?.cancel()

        // Capture channel references to unsubscribe after deinit completes
        // Note: We can't await in deinit, so unsubscribe happens asynchronously
        let notesChannelCopy = notesChannel
        let activitiesChannelCopy = activitiesChannel

        Task.detached {
            await notesChannelCopy?.unsubscribe()
            await activitiesChannelCopy?.unsubscribe()
            Logger.database.info("🔌 [ListingDetailStore] Unsubscribed channels for listing \(listingIdCopy)")
        }
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
        Logger.database.info("🔁 [ListingDetailStore] fetchListingData() starting for listing \(self.listingId)")
        isLoading = true
        errorMessage = nil

        do {
            // Fetch listing, activities, and notes in parallel
            Logger.database.info("🔁 [ListingDetailStore] Fetching listing \(self.listingId) from repository...")
            Logger.database.info("🔁 [ListingDetailStore] Fetching notes for listing \(self.listingId)...")
            Logger.database.info("🔁 [ListingDetailStore] Fetching activities for listing \(self.listingId)...")

            async let listingFetch = listingRepository.fetchListing(listingId)
            async let activitiesFetch = activityCoalescer.fetch(using: taskRepository)
            async let notesFetch = noteCoalescer.fetch(listingId: listingId, using: noteRepository)

            let (fetchedListing, allActivities, fetchedNotes) = try await (listingFetch, activitiesFetch, notesFetch)

            Logger.database.info("✅ [ListingDetailStore] Listing fetch complete (found: \(fetchedListing != nil))")
            Logger.database.info("✅ [ListingDetailStore] Notes fetch complete for listing \(self.listingId) (count: \(fetchedNotes.count))")
            Logger.database.info("✅ [ListingDetailStore] Activities fetch complete (total: \(allActivities.count))")

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
                "✅ [ListingDetailStore] Filtered \(self.activities.count) activities for this listing \(self.listingId)"
            )

            // Start realtime subscriptions AFTER initial load (only once)
            await setupRealtimeIfNeeded()
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

    /// Setup Realtime subscriptions once per store instance
    /// Guards against multiple calls to prevent duplicate channels
    private func setupRealtimeIfNeeded() async {
        guard !didSetupRealtime else {
            Logger.database.info("⏭️ [ListingDetailStore] Realtime already set up for listing \(self.listingId), skipping")
            return
        }

        Logger.database.info("📡 [ListingDetailStore] Setting up Realtime subscriptions for listing \(self.listingId)")
        await setupNotesRealtime()
        await setupActivitiesRealtime()
        didSetupRealtime = true
        Logger.database.info("✅ [ListingDetailStore] Realtime subscriptions complete for listing \(self.listingId)")
    }

    /// Teardown Realtime subscriptions when view disappears
    func teardownRealtime() async {
        guard didSetupRealtime else {
            Logger.database.info("⏭️ [ListingDetailStore] Realtime not set up for listing \(self.listingId), nothing to tear down")
            return
        }

        Logger.database.info("🔌 [ListingDetailStore] Tearing down Realtime for listing \(self.listingId)")

        // Cancel stream tasks first
        notesRealtimeTask?.cancel()
        activitiesRealtimeTask?.cancel()
        Logger.database.info("🚫 [ListingDetailStore] Cancelled Realtime tasks for listing \(self.listingId)")

        // Unsubscribe channels
        await notesChannel?.unsubscribe()
        await activitiesChannel?.unsubscribe()
        Logger.database.info("📡 [ListingDetailStore] Unsubscribed channels for listing \(self.listingId)")

        // Clear references
        notesChannel = nil
        activitiesChannel = nil
        notesRealtimeTask = nil
        activitiesRealtimeTask = nil
        didSetupRealtime = false

        Logger.database.info("✅ [ListingDetailStore] Realtime teardown complete for listing \(self.listingId)")
    }

    /// Setup realtime subscription for notes on this listing
    /// Called only once per store instance by setupRealtimeIfNeeded()
    private func setupNotesRealtime() async {
        let channelName = "listing_\(listingId)_notes"

        Logger.database.info("⚙️ [ListingDetailStore] Creating Realtime channel: \(channelName)")
        let channel = supabase.realtimeV2.channel(channelName)
        notesChannel = channel

        notesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                Logger.database.info("⚙️ [ListingDetailStore] Configuring postgresChange for listing_notes on \(channelName) with filter listing_id=\(self.listingId)")
                let stream = channel.postgresChange(AnyAction.self, table: "listing_notes", filter: .eq("listing_id", value: self.listingId))

                // Subscribe to start receiving events
                Logger.database.info("⚙️ [ListingDetailStore] Subscribing to channel \(channelName)")
                try await channel.subscribeWithError()
                Logger.database.info("📡 [ListingDetailStore] Subscribed to \(channelName)")

                // Listen for changes - task cancellation stops this loop
                for await change in stream {
                    await self.handleNotesChange(change)
                }
                Logger.database.info("🔚 [ListingDetailStore] Stream ended for \(channelName)")
            } catch is CancellationError {
                Logger.database.info("🚫 [ListingDetailStore] Notes realtime task cancelled for listing \(self.listingId)")
            } catch {
                Logger.database.error("❌ [ListingDetailStore] Notes realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime note changes - debounced refresh strategy
    private func handleNotesChange(_ change: AnyAction) async {
        Logger.database.info("🔔 [ListingDetailStore] Realtime change for table listing_notes, listing \(self.listingId). Scheduling debounced refetch.")

        // Cancel previous debounce task if still pending
        notesRefetchTask?.cancel()

        // Start new debounced task (500ms delay)
        notesRefetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else {
                    Logger.database.info("🚫 [ListingDetailStore] Notes refetch cancelled (debounced) for listing \(self.listingId)")
                    return
                }

                let startTime = ContinuousClock.now
                Logger.database.info("🔁 [ListingDetailStore] Refetching notes via coalescer for listing \(self.listingId)...")

                let fetchedNotes = try await noteCoalescer.fetch(listingId: listingId, using: noteRepository)
                notes = fetchedNotes

                // Rebuild ID set for deduplication
                noteIds = Set(notes.map(\.id))

                let duration = ContinuousClock.now - startTime
                Logger.database.info("✅ [ListingDetailStore] Realtime refetch complete: \(self.notes.count) notes for listing \(self.listingId) in \(duration)")
            } catch is CancellationError {
                Logger.database.info("🚫 [ListingDetailStore] Notes refetch cancelled for listing \(self.listingId)")
            } catch {
                Logger.database.error("❌ [ListingDetailStore] Failed to refresh notes after Realtime change: \(error.localizedDescription)")
            }
        }
    }

    /// Setup realtime subscription for activities on this listing
    /// Called only once per store instance by setupRealtimeIfNeeded()
    private func setupActivitiesRealtime() async {
        let channelName = "listing_\(listingId)_activities"

        Logger.database.info("⚙️ [ListingDetailStore] Creating Realtime channel: \(channelName)")
        let channel = supabase.realtimeV2.channel(channelName)
        activitiesChannel = channel

        activitiesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                Logger.database.info("⚙️ [ListingDetailStore] Configuring postgresChange for activities on \(channelName) with filter listing_id=\(self.listingId)")
                let stream = channel.postgresChange(AnyAction.self, table: "activities", filter: .eq("listing_id", value: self.listingId))

                // Subscribe to start receiving events
                Logger.database.info("⚙️ [ListingDetailStore] Subscribing to channel \(channelName)")
                try await channel.subscribeWithError()
                Logger.database.info("📡 [ListingDetailStore] Subscribed to \(channelName)")

                // Listen for changes - task cancellation stops this loop
                for await change in stream {
                    await self.handleActivitiesChange(change)
                }
                Logger.database.info("🔚 [ListingDetailStore] Stream ended for \(channelName)")
            } catch is CancellationError {
                Logger.database.info("🚫 [ListingDetailStore] Activities realtime task cancelled for listing \(self.listingId)")
            } catch {
                Logger.database.error("❌ [ListingDetailStore] Activities realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime activity changes - debounced refresh strategy
    private func handleActivitiesChange(_ change: AnyAction) async {
        Logger.database.info("🔔 [ListingDetailStore] Realtime change for table activities, listing \(self.listingId). Scheduling debounced refetch.")

        // Cancel previous debounce task if still pending
        activitiesRefetchTask?.cancel()

        // Start new debounced task (500ms delay)
        activitiesRefetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else {
                    Logger.database.info("🚫 [ListingDetailStore] Activities refetch cancelled (debounced) for listing \(self.listingId)")
                    return
                }

                let startTime = ContinuousClock.now
                Logger.database.info("🔁 [ListingDetailStore] Refetching activities via coalescer for listing \(self.listingId)...")

                let allActivities = try await activityCoalescer.fetch(using: taskRepository)
                activities = allActivities.map(\.task).filter { $0.listingId == listingId }

                let duration = ContinuousClock.now - startTime
                Logger.database.info("✅ [ListingDetailStore] Realtime refetch complete: \(self.activities.count) activities for listing \(self.listingId) in \(duration)")
            } catch is CancellationError {
                Logger.database.info("🚫 [ListingDetailStore] Activities refetch cancelled for listing \(self.listingId)")
            } catch {
                Logger.database.error("❌ [ListingDetailStore] Failed to refresh activities after Realtime change: \(error.localizedDescription)")
            }
        }
    }
}

