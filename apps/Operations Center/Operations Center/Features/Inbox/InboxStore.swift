//
//  InboxStore.swift
//  Operations Center
//
//  Store for inbox view - manages both agent tasks and activities
//

import Dependencies
import Foundation
import Observation
import OperationsCenterKit
import OSLog
import Supabase

@Observable
@MainActor
final class InboxStore {
    // MARK: - State

    var tasks: [TaskWithMessages] = []
    var listings: [ListingWithDetails] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    /// Note input text per listing - managed via binding
    var listingNoteInputs: [String: String] = [:]

    /// Pending note IDs for optimistic updates
    private var pendingNoteIds = Set<String>()

    // MARK: - Dependencies

    private let taskRepository: TaskRepositoryClient
    private let listingRepository: ListingRepositoryClient
    private let noteRepository: ListingNoteRepositoryClient
    private let realtorRepository: RealtorRepositoryClient
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    /// Coalescers for request deduplication
    private let activityCoalescer: ActivityFetchCoalescer
    private let noteCoalescer: NoteFetchCoalescer

    /// Supabase client for realtime subscriptions
    @ObservationIgnored
    private let supabase: SupabaseClient

    /// Realtime channels (created once, prevents "postgresChange after joining" error)
    @ObservationIgnored
    private lazy var acknowledgementsChannel = supabase.realtimeV2.channel("inbox_acknowledgments")

    @ObservationIgnored
    private lazy var agentTasksChannel = supabase.realtimeV2.channel("inbox_agent_tasks")

    @ObservationIgnored
    private lazy var activitiesChannel = supabase.realtimeV2.channel("inbox_activities")

    /// Realtime subscription tasks
    @ObservationIgnored
    private var acknowledgementsRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var agentTasksRealtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var activitiesRealtimeTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Full initializer with optional initial data for previews
    init(
        taskRepository: TaskRepositoryClient,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        realtorRepository: RealtorRepositoryClient,
        supabase: SupabaseClient,
        activityCoalescer: ActivityFetchCoalescer,
        noteCoalescer: NoteFetchCoalescer,
        initialTasks: [TaskWithMessages] = [],
        initialListings: [ListingWithDetails] = []
    ) {
        self.taskRepository = taskRepository
        self.listingRepository = listingRepository
        self.noteRepository = noteRepository
        self.realtorRepository = realtorRepository
        self.supabase = supabase
        self.activityCoalescer = activityCoalescer
        self.noteCoalescer = noteCoalescer
        self.tasks = initialTasks
        self.listings = initialListings
    }

    deinit {
        Task.detached { [weak self] in
            guard let self else { return }
            await acknowledgementsChannel.unsubscribe()
            await agentTasksChannel.unsubscribe()
            await activitiesChannel.unsubscribe()
        }
        acknowledgementsRealtimeTask?.cancel()
        agentTasksRealtimeTask?.cancel()
        activitiesRealtimeTask?.cancel()
    }

    // MARK: - Preview Support

    /// Preview factory for SwiftUI previews
    /// Resolves actor isolation issues in preview contexts
    @MainActor
    static func makePreview(
        supabase: SupabaseClient,
        initialTasks: [TaskWithMessages] = [],
        initialListings: [ListingWithDetails] = []
    ) -> InboxStore {
        InboxStore(
            taskRepository: .preview,
            listingRepository: .preview,
            noteRepository: .preview,
            realtorRepository: .preview,
            supabase: supabase,
            activityCoalescer: ActivityFetchCoalescer(),
            noteCoalescer: NoteFetchCoalescer(),
            initialTasks: initialTasks,
            initialListings: initialListings
        )
    }

    // MARK: - Public Methods

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentUserId = try await authClient.currentUserId()

            // Fetch agent tasks, activities, and unacknowledged listings concurrently
            // Activities use coalescer to prevent duplicate fetches
            async let agentTasks = taskRepository.fetchTasks()
            async let activityDetails = activityCoalescer.fetch(using: taskRepository)
            async let unacknowledgedListingIds = listingRepository.fetchUnacknowledgedListings(currentUserId)

            tasks = try await agentTasks
            let activities = try await activityDetails
            let unacknowledgedIds = Set(try await unacknowledgedListingIds.map { $0.id })

            Logger.database.info("📊 InboxStore: \(self.tasks.count) agent tasks, \(activities.count) activities")
            Logger.database.info("🔔 Unacknowledged listing IDs: \(unacknowledgedIds)")

            // Filter activities to only show those from unacknowledged listings
            let filteredActivities = activities.filter { unacknowledgedIds.contains($0.listing.id) }

            Logger.database.info(
                """
                ✂️ After acknowledgment filter: \(filteredActivities.count) activities \
                (dropped \(activities.count - filteredActivities.count))
                """
            )

            // Group activities by listing
            let groupedByListing = Dictionary(grouping: filteredActivities) { $0.listing.id }

            // Build ListingWithDetails for each listing - PARALLEL EXECUTION
            // Use task group to fetch notes and realtors concurrently for all listings
            listings = await withTaskGroup(of: ListingWithDetails.self) { group in
                for (listingId, activityGroup) in groupedByListing {
                    guard let firstActivity = activityGroup.first else { continue }
                    let listing = firstActivity.listing

                    group.addTask {
                        // Fetch notes and realtor in parallel for this listing
                        async let fetchedNotesResult = self.fetchNotes(for: listingId)
                        async let realtorResult: (Realtor?, Bool) = {
                            if let realtorId = listing.realtorId {
                                return await self.fetchRealtor(for: realtorId, listingId: listingId)
                            }
                            return (nil, false)
                        }()

                        let (fetchedNotes, notesError) = await fetchedNotesResult
                        let (realtor, realtorError) = await realtorResult

                        return ListingWithDetails(
                            listing: listing,
                            realtor: realtor,
                            activities: activityGroup.map { $0.task },
                            notes: fetchedNotes,
                            hasNotesError: notesError,
                            hasMissingRealtor: realtorError
                        )
                    }
                }

                // Collect results
                var results: [ListingWithDetails] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            // Start realtime subscriptions AFTER initial load
            await setupRealtimeSubscriptions()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await fetchTasks()
    }

    // MARK: - Private Helpers

    /// Fetch notes for a listing, logging any errors
    /// Uses coalescer to prevent duplicate fetches for same listing
    private func fetchNotes(for listingId: String) async -> (notes: [ListingNote], hasError: Bool) {
        do {
            let notes = try await noteCoalescer.fetch(listingId: listingId, using: noteRepository)
            return (notes, false)
        } catch {
            Logger.database.error(
                "Failed to fetch notes for listing \(listingId): \(error.localizedDescription)"
            )
            return ([], true)
        }
    }

    /// Fetch realtor for a listing, logging any errors
    private func fetchRealtor(for realtorId: String, listingId: String) async -> (realtor: Realtor?, hasError: Bool) {
        do {
            let realtor = try await realtorRepository.fetchRealtor(realtorId)
            return (realtor, false)
        } catch {
            Logger.database.error(
                """
                Failed to fetch realtor \(realtorId) for listing \(listingId): \
                \(error.localizedDescription)
                """
            )
            return (nil, true)
        }
    }

    // MARK: - Expansion State

    func toggleExpansion(for taskId: String) {
        if expandedTaskId == taskId {
            expandedTaskId = nil
        } else {
            expandedTaskId = taskId
        }
    }

    func isExpanded(_ taskId: String) -> Bool {
        expandedTaskId == taskId
    }

    // MARK: - Agent Task Actions

    func claimTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            let userId = try await authClient.currentUserId()
            _ = try await taskRepository.claimTask(task.id, userId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            let userId = try await authClient.currentUserId()
            try await taskRepository.deleteTask(task.id, userId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Activity Actions

    func claimActivity(_ activity: Activity) async {
        errorMessage = nil

        do {
            let userId = try await authClient.currentUserId()
            _ = try await taskRepository.claimActivity(activity.id, userId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteActivity(_ activity: Activity) async {
        errorMessage = nil

        do {
            let userId = try await authClient.currentUserId()
            try await taskRepository.deleteActivity(activity.id, userId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Note Actions

    /// Submit note with optimistic update for instant UI feedback
    func submitNote(for listingId: String) {
        let inputText = listingNoteInputs[listingId] ?? ""
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Find the listing
        guard let listingIndex = listings.firstIndex(where: { $0.listing.id == listingId }) else {
            return
        }

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

        // Instant UI update - direct mutation triggers @Observable
        listings[listingIndex].notes.append(optimisticNote)
        pendingNoteIds.insert(tempId)
        listingNoteInputs[listingId] = ""

        // Fire async network call
        Task {
            await createNoteInBackground(tempId: tempId, listingId: listingId, content: trimmed)
        }
    }

    /// Create note in background - replace optimistic version with server response
    private func createNoteInBackground(tempId: String, listingId: String, content: String) async {
        do {
            let createdNote = try await noteRepository.createNote(listingId, content)

            // Find the listing and replace temp note with server response
            if let listingIndex = listings.firstIndex(where: { $0.listing.id == listingId }),
               let noteIndex = listings[listingIndex].notes.firstIndex(where: { $0.id == tempId }) {
                listings[listingIndex].notes[noteIndex] = createdNote
            }
            pendingNoteIds.remove(tempId)

            Logger.database.info("Created note for listing \(listingId)")
        } catch {
            // Revert optimistic update
            if let listingIndex = listings.firstIndex(where: { $0.listing.id == listingId }) {
                listings[listingIndex].notes.removeAll { $0.id == tempId }
            }
            pendingNoteIds.remove(tempId)

            Logger.database.error("Failed to create note: \(error.localizedDescription)")
            errorMessage = "Failed to create note: \(error.localizedDescription)"
        }
    }

    // MARK: - Listing Actions

    func acknowledgeListing(_ listingId: String) async {
        errorMessage = nil

        do {
            _ = try await listingRepository.acknowledgeListing(listingId, await authClient.currentUserId())

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Realtime Subscriptions

    /// Setup all realtime subscriptions - inbox is a hub, needs multiple channels
    private func setupRealtimeSubscriptions() async {
        await setupAcknowledgementsRealtime()
        await setupAgentTasksRealtime()
        await setupActivitiesRealtime()
    }

    /// Setup realtime subscription for listing acknowledgments
    /// When someone acks a listing, it should vanish from everyone's inbox
    private func setupAcknowledgementsRealtime() async {
        acknowledgementsRealtimeTask?.cancel()

        acknowledgementsRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = acknowledgementsChannel.postgresChange(AnyAction.self, table: "listing_acknowledgments")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await acknowledgementsChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleAcknowledgementChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Acknowledgments realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime acknowledgment changes - simple refresh strategy
    private func handleAcknowledgementChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Acknowledgment change detected, refreshing inbox...")

        // Simple approach: re-fetch everything
        // Someone acked a listing, so it should disappear from unacknowledged listings
        await fetchTasks()
    }

    /// Setup realtime subscription for agent tasks
    /// When someone claims or updates a task, everyone sees it instantly
    private func setupAgentTasksRealtime() async {
        agentTasksRealtimeTask?.cancel()

        agentTasksRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = agentTasksChannel.postgresChange(AnyAction.self, table: "agent_tasks")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await agentTasksChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleAgentTaskChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Agent tasks realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime agent task changes - simple refresh strategy
    private func handleAgentTaskChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Agent task change detected, refreshing inbox...")

        // Simple approach: re-fetch everything
        await fetchTasks()
    }

    /// Setup realtime subscription for activities
    /// When new activities appear or existing ones update, everyone sees it
    private func setupActivitiesRealtime() async {
        activitiesRealtimeTask?.cancel()

        activitiesRealtimeTask = Task { [weak self] in
            guard let self else { return }
            do {
                // CRITICAL: Configure stream BEFORE subscribing (per Supabase Realtime V2 docs)
                let stream = activitiesChannel.postgresChange(AnyAction.self, table: "activities")

                // Now subscribe to start receiving events (safe to call multiple times)
                try await activitiesChannel.subscribeWithError()

                // Listen for changes - structured concurrency handles cancellation
                for await change in stream {
                    await self.handleActivityChange(change)
                }
            } catch is CancellationError {
                return
            } catch {
                Logger.database.error("Activities realtime error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle realtime activity changes - simple refresh strategy
    private func handleActivityChange(_ change: AnyAction) async {
        Logger.database.info("Realtime: Activity change detected, refreshing inbox...")

        // Simple approach: re-fetch everything
        // Activities are filtered by unacknowledged listings anyway
        await fetchTasks()
    }
}
