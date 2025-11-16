//
//  ListingDetailStore.swift
//  Operations Center
//
//  Listing Detail screen store - manages listing data, notes, activities
//  Per TASK_MANAGEMENT_SPEC.md lines 338-375
//

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

    // MARK: - Initialization

    init(
        listingId: String,
        listingRepository: ListingRepositoryClient,
        noteRepository: ListingNoteRepositoryClient
    ) {
        self.listingId = listingId
        self.listingRepository = listingRepository
        self.noteRepository = noteRepository
    }

    // MARK: - Actions

    /// Fetch listing data and notes
    func fetchListingData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch listing and notes in parallel
            async let activitiesFetch = listingRepository.fetchListing(listingId)
            async let notesFetch = noteRepository.fetchNotes(listingId)

            let (fetchedListing, fetchedNotes) = try await (activitiesFetch, notesFetch)

            listing = fetchedListing
            notes = fetchedNotes

            Logger.database.info("Fetched listing \(self.listingId) with \(self.notes.count) notes")
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
            let currentUserId = "current-user" // NOTE: Get from auth
            let createdNote = try await noteRepository.createNote(listingId, trimmedText, currentUserId)

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
}
