//
//  InboxStore.swift
//  Operations Center
//
//  Store for inbox view - manages both agent tasks and activities
//

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
    private let noteRepository: ListingNoteRepositoryClient
    private let realtorRepository: RealtorRepositoryClient

    /// Current authenticated user ID
    /// NOTE: Replace with actual authenticated user ID from auth service
    private var currentUserId: String {
        "current-staff-id"
    }

    // MARK: - Initialization

    /// Full initializer with optional initial data for previews
    init(
        taskRepository: TaskRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        realtorRepository: RealtorRepositoryClient,
        initialTasks: [TaskWithMessages] = [],
        initialListings: [ListingWithDetails] = []
    ) {
        self.taskRepository = taskRepository
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
            // Fetch agent tasks and activities concurrently
            async let agentTasks = taskRepository.fetchTasks()
            async let activityDetails = taskRepository.fetchActivities()

            tasks = try await agentTasks
            let activities = try await activityDetails

            // Group activities by listing
            let groupedByListing = Dictionary(grouping: activities) { $0.listing.id }

            // Build ListingWithDetails for each listing
            var listingDetails: [ListingWithDetails] = []
            for (listingId, activityGroup) in groupedByListing {
                guard let firstActivity = activityGroup.first else { continue }
                let listing = firstActivity.listing

                // Fetch notes - log errors and track failure
                var fetchedNotes: [ListingNote] = []
                var notesError = false
                do {
                    fetchedNotes = try await noteRepository.fetchNotes(listingId)
                } catch {
                    Logger.database.error(
                        "Failed to fetch notes for listing \(listingId): \(error.localizedDescription)"
                    )
                    notesError = true
                }

                // Fetch realtor - log errors and track failure
                var realtor: Realtor?
                var realtorError = false
                if let realtorId = listing.realtorId {
                    do {
                        realtor = try await realtorRepository.fetchRealtor(realtorId)
                    } catch {
                        Logger.database.error(
                            """
                            Failed to fetch realtor \(realtorId) for listing \(listingId): \
                            \(error.localizedDescription)
                            """
                        )
                        realtorError = true
                    }
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
            _ = try await taskRepository.claimTask(task.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: AgentTask) async {
        errorMessage = nil

        do {
            try await taskRepository.deleteTask(task.id, currentUserId)

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
            _ = try await taskRepository.claimActivity(activity.id, currentUserId)

            // Refresh the list
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteActivity(_ activity: Activity) async {
        errorMessage = nil

        do {
            try await taskRepository.deleteActivity(activity.id, currentUserId)

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
            _ = try await noteRepository.createNote(listingId, content, currentUserId)

            // Refresh to get updated notes
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
