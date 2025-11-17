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

    /// Fetches agent tasks, activity details, and unacknowledged listings, then updates the store's task and listing state.
    /// 
    /// Concurrently retrieves agent tasks, activity details, and the current user's unacknowledged listing IDs, filters activities to only those tied to unacknowledged listings, groups activities by listing, and for each listing fetches notes and realtor details to build `ListingWithDetails`. Updates `tasks`, `listings`, `isLoading`, and `errorMessage` to reflect the operation's outcome. Sets `errorMessage` to the error's localized description if any part fails.

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentUserId = authClient.currentUserId()

            // Fetch agent tasks, activities, and unacknowledged listings concurrently
            async let agentTasks = taskRepository.fetchTasks()
            async let activityDetails = taskRepository.fetchActivities()
            async let unacknowledgedListingIds = listingRepository.fetchUnacknowledgedListings(currentUserId)

            tasks = try await agentTasks
            let activities = try await activityDetails
            let unacknowledgedIds = Set(try await unacknowledgedListingIds.map { $0.id })

            // Filter activities to only show those from unacknowledged listings
            let filteredActivities = activities.filter { unacknowledgedIds.contains($0.listing.id) }

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

    /// Claims the specified agent task on behalf of the current user and refreshes the inbox.
    /// - Parameter task: The `AgentTask` to claim. On success the store's task list is refreshed.
    /// - Note: If claiming fails, `errorMessage` is set to the error's localized description.

    func claimTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            _ = try await taskRepository.claimTask(task.id, authClient.currentUserId())

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes the specified agent task for the current user and refreshes the inbox data.
    /// - Parameter task: The agent task to delete; deletion is performed on behalf of the current authenticated user.
    /// - Note: On failure, `errorMessage` is set to the error's `localizedDescription`.
    func deleteTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            try await taskRepository.deleteTask(task.id, authClient.currentUserId())

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Claims the specified activity for the current user and refreshes the inbox listing.
    /// 
    /// On failure, sets `errorMessage` to the error's localized description and leaves the store state unchanged aside from the error.
    /// - Parameter activity: The activity to claim.

    func claimActivity(_ activity: Activity) async {
        errorMessage = nil

        do {
            _ = try await taskRepository.claimActivity(activity.id, authClient.currentUserId())

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes the specified activity on behalf of the current user and refreshes the inbox data.
    /// Clears any existing error message before attempting deletion; if deletion fails, sets `errorMessage` to the error's localized description.
    /// - Parameter activity: The activity to delete.
    func deleteActivity(_ activity: Activity) async {
        errorMessage = nil

        do {
            try await taskRepository.deleteActivity(activity.id, authClient.currentUserId())

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Adds a new note to the specified listing and refreshes inbox data.
    /// - Parameters:
    ///   - listingId: The identifier of the listing to add the note to.
    ///   - content: The text content of the note.
    /// - Note: On failure, sets `errorMessage` to the error's localized description.

    func addNote(to listingId: String, content: String) async {
        errorMessage = nil

        do {
            _ = try await noteRepository.createNote(listingId, content, authClient.currentUserId())

            // Refresh to get updated notes
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Acknowledges the specified listing for the current user and refreshes the store state.
    /// - Parameters:
    ///   - listingId: The identifier of the listing to acknowledge.
    /// - Note: On failure, `errorMessage` is set to the error's localized description.

    func acknowledgeListing(_ listingId: String) async {
        errorMessage = nil

        do {
            _ = try await listingRepository.acknowledgeListing(listingId, authClient.currentUserId())

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}