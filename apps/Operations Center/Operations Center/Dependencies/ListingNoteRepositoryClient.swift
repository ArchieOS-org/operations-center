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
import Dependencies

/// Repository client for listing notes operations
public struct ListingNoteRepositoryClient {
    public var fetchNotes: @Sendable (_ listingId: String) async throws -> [ListingNote]
    public var createNote: @Sendable (
        _ listingId: String,
        _ content: String
    ) async throws -> ListingNote
    public var deleteNote: @Sendable (_ noteId: String) async throws -> Void
}

// MARK: - Live Implementation

extension ListingNoteRepositoryClient {
    @MainActor
    public static var live: Self {
        @Dependency(\.authClient) var authClient

        return Self(
            fetchNotes: { listingId in
                Logger.database.info("Fetching notes for listing: \(listingId)")
                let notes: [ListingNote] = try await supabase
                    .from("listing_notes")
                    .select()
                    .eq("listing_id", value: listingId)
                    .order("created_at", ascending: true)
                    .execute()
                    .value
                Logger.database.info("Fetched \(notes.count) notes for listing \(listingId)")
                return notes
            },
            createNote: { listingId, content in
                Logger.database.info("Creating note for listing: \(listingId)")

                // Get current authenticated user ID
                let userId = try await authClient.currentUserId()

                // Fetch user's display name from staff table
                let staff: [Staff] = try await supabase
                    .from("staff")
                    .select()
                    .eq("staff_id", value: userId)
                    .execute()
                    .value

                let userName = staff.first?.name
                let noteId = UUID().uuidString
                let now = Date()

                let newNote = ListingNote(
                    id: noteId,
                    listingId: listingId,
                    content: content,
                    type: "general",
                    createdBy: userId,
                    createdByName: userName,
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
}

// MARK: - Preview Implementation

extension ListingNoteRepositoryClient {
    public static let preview = Self(
        fetchNotes: { _ in
            // Return mock notes for all listings
            return [
                ListingNote.mock1,
                ListingNote.mock2,
                ListingNote.mock3
            ]
        },
        createNote: { listingId, content in
            // Return a new mock note
            return ListingNote(
                id: UUID().uuidString,
                listingId: listingId,
                content: content,
                type: "general",
                createdBy: "preview-staff-id",
                createdByName: "Preview User",
                createdAt: Date(),
                updatedAt: Date()
            )
        },
        deleteNote: { _ in
            // No-op for preview
        }
    )
}
