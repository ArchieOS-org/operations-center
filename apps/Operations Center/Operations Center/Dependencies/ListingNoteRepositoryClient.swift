//
//  ListingNoteRepositoryClient.swift
//  Operations Center
//
//  Repository for listing notes data access
//  Per Context7 pattern: Repository with live/preview implementations
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

/// Repository client for listing notes operations
public struct ListingNoteRepositoryClient {
    public var fetchNotes: @Sendable (_ listingId: String) async throws -> [ListingNote]
    public var createNote: @Sendable (
        _ listingId: String,
        _ content: String,
        _ createdBy: String
    ) async throws -> ListingNote
    public var deleteNote: @Sendable (_ noteId: String) async throws -> Void
}

// MARK: - Live Implementation

extension ListingNoteRepositoryClient {
    public static let live = Self(
        fetchNotes: { listingId in
            Logger.database.info("Fetching notes for listing: \(listingId)")
            let notes: [ListingNote] = try await supabase
                .from("listing_notes")
                .select()
                .eq("listing_id", value: listingId)
                .order("created_at", ascending: false)
                .execute()
                .value
            Logger.database.info("Fetched \(notes.count) notes for listing \(listingId)")
            return notes
        },
        createNote: { listingId, content, createdBy in
            Logger.database.info("Creating note for listing: \(listingId)")
            let noteId = UUID().uuidString
            let now = Date()

            let newNote = ListingNote(
                id: noteId,
                listingId: listingId,
                content: content,
                type: "general",
                createdBy: createdBy,
                createdAt: now,
                updatedAt: now
            )

            let response: [ListingNote] = try await supabase
                .from("listing_notes")
                .insert(newNote)
                .select()
                .execute()
                .value

            guard let createdNote = response.first else {
                throw NSError(domain: "ListingNoteRepository", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create note"
                ])
            }

            Logger.database.info("Created note \(noteId) for listing \(listingId)")
            return createdNote
        },
        deleteNote: { noteId in
            Logger.database.info("Deleting note: \(noteId)")
            try await supabase
                .from("listing_notes")
                .delete()
                .eq("note_id", value: noteId)
                .execute()
            Logger.database.info("Deleted note \(noteId)")
        }
    )
}

// MARK: - Preview Implementation

extension ListingNoteRepositoryClient {
    public static let preview = Self(
        fetchNotes: { listingId in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Return mock notes for all listings
            return [
                ListingNote.mock1,
                ListingNote.mock2,
                ListingNote.mock3
            ]
        },
        createNote: { listingId, content, createdBy in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            // Return a new mock note
            return ListingNote(
                id: UUID().uuidString,
                listingId: listingId,
                content: content,
                type: "general",
                createdBy: createdBy,
                createdAt: Date(),
                updatedAt: Date()
            )
        },
        deleteNote: { noteId in
            // Simulate network delay
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            // No-op for preview
        }
    )
}
