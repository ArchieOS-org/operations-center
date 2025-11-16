//
//  InboxStore.swift
//  Operations Center
//
//  Store for inbox view - manages both agent tasks and activities
//

import Foundation
import Observation
import OperationsCenterKit

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

                // Fetch notes and realtor concurrently
                async let notes = noteRepository.fetchNotes(listingId)

                let realtor: Realtor?
                if let realtorId = listing.realtorId {
                    realtor = try? await realtorRepository.fetchRealtor(realtorId)
                } else {
                    realtor = nil
                }

                let listingWithDetails = ListingWithDetails(
                    listing: listing,
                    realtor: realtor,
                    activities: activityGroup.map { $0.task },
                    notes: (try? await notes) ?? []
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
            // Get current user ID - for now use a placeholder
            // swiftlint:disable:next todo
            // TODO: Replace with actual authenticated user ID
            let currentUserId = "current-staff-id"

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
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

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
            // Get current user ID
            let currentUserId = "current-staff-id"

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
            // Get current user ID for audit trail
            let currentUserId = "current-staff-id"

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
            // Get current user ID
            let currentUserId = "current-staff-id"

            _ = try await noteRepository.createNote(listingId, content, currentUserId)

            // Refresh to get updated notes
            await fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
