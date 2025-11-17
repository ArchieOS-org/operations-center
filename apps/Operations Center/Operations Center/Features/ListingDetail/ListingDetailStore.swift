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

/// Store for Listing Detail screen - see and claim activities within a listing
/// Per spec: "Purpose: See and claim Activities within a Listing"
@Observable
@MainActor
final class ListingDetailStore {
    // MARK: - Properties

    /// The listing being displayed
    private(set) var listing: Listing?

    /// Notes for this listing
    private(set) var notes: [ListingNote] = []

    /// Activities for this listing
    private(set) var activities: [Activity] = []

    /// Expanded activity ID for UI state
    var expandedActivityId: String?

    /// New note input text
    var newNoteText: String = ""

    /// Error message to display
    var errorMessage: String?

    /// Loading state
    private(set) var isLoading = false

    /// Repositories for data access
    private let listingId: String
    private let listingRepository: ListingRepositoryClient
    private let noteRepository: ListingNoteRepositoryClient
    private let taskRepository: TaskRepositoryClient

    /// Authentication client for current user ID
    @ObservationIgnored @Dependency(\.authClient) private var authClient

    // MARK: - Initialization

    init(
        listingId: String,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient,
        taskRepository: TaskRepositoryClient
    ) {
        self.listingId = listingId
        self.listingRepository = listingRepository
        self.noteRepository = noteRepository
        self.taskRepository = taskRepository
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
            async let activitiesFetch = taskRepository.fetchActivities()
            async let notesFetch = noteRepository.fetchNotes(listingId)

            let (fetchedListing, allActivities, fetchedNotes) = try await (listingFetch, activitiesFetch, notesFetch)

            listing = fetchedListing
            // Filter activities to only those for this listing
            activities = allActivities.map { $0.task }.filter { $0.listingId == listingId }
            notes = fetchedNotes

            Logger.database.info("Fetched listing \(self.listingId) with \(self.activities.count) activities and \(self.notes.count) notes")
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

    /// Create a new note
    /// Per spec: "Type, press Enter to save" (lines 353)
    func createNote() async {
        // Trim whitespace
        let trimmedText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate note has content
        guard !trimmedText.isEmpty else {
            return
        }

        do {
            let createdNote = try await noteRepository.createNote(listingId, trimmedText, authClient.currentUserId())

            // Add new note to beginning of list
            notes.insert(createdNote, at: 0)

            // Clear input
            newNoteText = ""

            Logger.database.info("Created note for listing \(self.listingId)")
        } catch {
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
        let userId = authClient.currentUserId()

        do {
            _ = try await taskRepository.claimActivity(activity.id, userId)
            await fetchListingData() // Refresh
        } catch {
            errorMessage = "Failed to claim activity: \(error.localizedDescription)"
        }
    }

    /// Delete an activity
    func deleteActivity(_ activity: Activity) async {
        do {
            try await taskRepository.deleteActivity(activity.id, authClient.currentUserId())
            await fetchListingData() // Refresh
        } catch {
            errorMessage = "Failed to delete activity: \(error.localizedDescription)"
        }
    }
}
