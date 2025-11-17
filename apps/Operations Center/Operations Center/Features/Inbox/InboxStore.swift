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

@Observable
@MainActor
final class InboxStore {
    // MARK: - State

    var tasks: [TaskWithMessages] = []
    var listings: [ListingWithDetails] = []
    var expandedTaskId: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let taskRepository: TaskRepositoryClient
    private let listingRepository: ListingRepositoryClient
    private let noteRepository: ListingNoteRepositoryClient
    private let realtorRepository: RealtorRepositoryClient
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    /// Full initializer with optional initial data for previews
    init(
        taskRepository: TaskRepositoryClient,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        realtorRepository: RealtorRepositoryClient,
        initialTasks: [TaskWithMessages] = [],
        initialListings: [ListingWithDetails] = []
    ) {
        self.taskRepository = taskRepository
        self.listingRepository = listingRepository
        self.noteRepository = noteRepository
        self.realtorRepository = realtorRepository
        self.tasks = initialTasks
        self.listings = initialListings
    }

    // MARK: - Public Methods

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentUserId = try await authClient.currentUserId()

            // Fetch agent tasks, activities, and unacknowledged listings concurrently
            async let agentTasks = taskRepository.fetchTasks()
            async let activityDetails = taskRepository.fetchActivities()
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

            // Build ListingWithDetails for each listing
            var listingDetails: [ListingWithDetails] = []
            for (listingId, activityGroup) in groupedByListing {
                guard let firstActivity = activityGroup.first else { continue }
                let listing = firstActivity.listing

                // Fetch notes and realtor
                let (fetchedNotes, notesError) = await fetchNotes(for: listingId)
                var realtor: Realtor?
                var realtorError = false
                if let realtorId = listing.realtorId {
                    (realtor, realtorError) = await fetchRealtor(for: realtorId, listingId: listingId)
                }

                let listingWithDetails = ListingWithDetails(
                    listing: listing,
                    realtor: realtor,
                    activities: activityGroup.map { $0.task },
                    notes: fetchedNotes,
                    hasNotesError: notesError,
                    hasMissingRealtor: realtorError
                )
                listingDetails.append(listingWithDetails)
            }

            listings = listingDetails

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
    private func fetchNotes(for listingId: String) async -> (notes: [ListingNote], hasError: Bool) {
        do {
            let notes = try await noteRepository.fetchNotes(listingId)
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

    func addNote(to listingId: String, content: String) async {
        errorMessage = nil

        do {
            let userId = try await authClient.currentUserId()
            _ = try await noteRepository.createNote(listingId, content, userId)

            // Refresh to get updated notes
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
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
}
