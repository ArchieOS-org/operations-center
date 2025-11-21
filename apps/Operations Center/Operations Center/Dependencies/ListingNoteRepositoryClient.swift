//
//  ListingNoteRepositoryClient.swift
//  Operations Center
//
//  Repository for listing notes data access
//  REWRITTEN: Fixed Codable mismatch and performance issues
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase
import Dependencies

/// Errors that can occur during note operations
public enum NoteError: LocalizedError {
    case staffNotFound(email: String)
    case invalidContent
    case missingUserInfo

    public var errorDescription: String? {
        switch self {
        case .staffNotFound(let email):
            return "Staff member with email \(email) not found"
        case .invalidContent:
            return "Note content is invalid"
        case .missingUserInfo:
            return "User information not available"
        }
    }
}

/// Minimal DTO for staff lookup - matches our SELECT query
private struct StaffLookupResult: Codable {
    let staffId: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case staffId = "staff_id"
        case name
    }
}

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
    public static func live(localDatabase: LocalDatabase) -> Self {
        @Dependency(\.authClient) var authClient

        return Self(
            fetchNotes: { listingId in
                let requestId = UUID().uuidString.prefix(8)
                Logger.database.info("🧾 [ListingNoteRepository] fetchNotes(\(listingId)) [req: \(requestId)] starting (local first)")

                // Read from local database first
                Logger.database.info("📱 [ListingNoteRepository] [req: \(requestId)] reading from local database...")
                let cachedNotes = try await MainActor.run { try localDatabase.fetchNotes(for: listingId) }
                Logger.database.info("📱 [ListingNoteRepository] [req: \(requestId)] local returned \(cachedNotes.count) notes")

                // Background refresh from Supabase
                Task.detached {
                    do {
                        Logger.database.info("☁️ [ListingNoteRepository] [req: \(requestId)] refreshing from Supabase...")
                        let notes: [ListingNote] = try await supabase
                            .from("listing_notes")
                            .select()
                            .eq("listing_id", value: listingId)
                            .order("created_at", ascending: false)
                            .execute()
                            .value

                        Logger.database.info("✅ [ListingNoteRepository] [req: \(requestId)] completed with result: \(notes.count) notes")
                        try await MainActor.run { try localDatabase.upsertNotes(notes) }
                        Logger.database.info("💾 [ListingNoteRepository] [req: \(requestId)] saved to local database")
                    } catch {
                        Logger.database.error("❌ [ListingNoteRepository] [req: \(requestId)] background refresh failed: \(error.localizedDescription)")
                    }
                }

                return cachedNotes
            },
            
            createNote: { listingId, content in
                let startTime = CFAbsoluteTimeGetCurrent()
                Logger.database.info("📝 [PERF] Creating note for listing: \(listingId) - START")

                // STEP 1: Get user ID (should be instant from JWT)
                let step1Start = CFAbsoluteTimeGetCurrent()
                let userId = try await authClient.currentUserId()
                let step1Time = (CFAbsoluteTimeGetCurrent() - step1Start) * 1000
                Logger.database.info("⚡️ [PERF] Step 1 - Got user ID: \(userId) in \(String(format: "%.0f", step1Time))ms")
                
                // STEP 2: Get session for email (cached by SDK)
                let step2Start = CFAbsoluteTimeGetCurrent()
                let session = try await supabase.auth.session
                guard let userEmail = session.user.email else {
                    Logger.database.error("❌ No email in session")
                    throw NoteError.missingUserInfo
                }
                let step2Time = (CFAbsoluteTimeGetCurrent() - step2Start) * 1000
                Logger.database.info("⚡️ [PERF] Step 2 - Got email: \(userEmail) in \(String(format: "%.0f", step2Time))ms")

                // STEP 3: Staff lookup
                let step3Start = CFAbsoluteTimeGetCurrent()
                Logger.database.info("🔍 Looking up staff by email: \(userEmail)")
                Logger.database.info("🔍 [DEBUG] Query: SELECT staff_id, name FROM staff WHERE email = '\(userEmail)' LIMIT 1")

                let staffResults: [StaffLookupResult] = try await supabase
                    .from("staff")
                    .select("staff_id, name")
                    .eq("email", value: userEmail)
                    .limit(1)
                    .execute()
                    .value
                
                let step3Time = (CFAbsoluteTimeGetCurrent() - step3Start) * 1000
                Logger.database.info("⚡️ [PERF] Step 3 - Staff query completed in \(String(format: "%.0f", step3Time))ms")
                Logger.database.info("🔍 [DEBUG] Query returned \(staffResults.count) results")

                guard let staff = staffResults.first else {
                    Logger.database.error("❌ Staff not found for email: \(userEmail)")
                    Logger.database.error("❌ [DEBUG] Possible causes:")
                    Logger.database.error("  1. Email doesn't exist in staff table")
                    Logger.database.error("  2. RLS policy is blocking the query")
                    Logger.database.error("  3. Table/column name mismatch")
                    throw NoteError.staffNotFound(email: userEmail)
                }

                Logger.database.info("✅ Found staff: \(staff.name) (ID: \(staff.staffId))")
                
                // STEP 4: Create note
                let step4Start = CFAbsoluteTimeGetCurrent()
                let noteId = UUID().uuidString
                let now = Date()

                let newNote = ListingNote(
                    id: noteId,
                    listingId: listingId,
                    content: content,
                    type: .general,
                    createdBy: userId,
                    createdByName: staff.name,
                    createdAt: now,
                    updatedAt: now
                )

                let createdNote: ListingNote = try await supabase
                    .from("listing_notes")
                    .insert(newNote)
                    .select()
                    .single()
                    .execute()
                    .value
                
                let step4Time = (CFAbsoluteTimeGetCurrent() - step4Start) * 1000
                let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

                Logger.database.info("⚡️ [PERF] Step 4 - Note insert completed in \(String(format: "%.0f", step4Time))ms")
                Logger.database.info("✅ [PERF] Created note \(noteId) - TOTAL TIME: \(String(format: "%.0f", totalTime))ms")
                Logger.database.info("📊 [PERF] Breakdown: UserID=\(String(format: "%.0f", step1Time))ms, Email=\(String(format: "%.0f", step2Time))ms, StaffLookup=\(String(format: "%.0f", step3Time))ms, Insert=\(String(format: "%.0f", step4Time))ms")

                // Update local database
                try await MainActor.run { try localDatabase.upsertNotes([createdNote]) }
                Logger.database.info("💾 Saved new note to local database")

                return createdNote
            },
            
            deleteNote: { noteId in
                Logger.database.info("🗑️ Deleting note: \(noteId)")
                
                try await supabase
                    .from("listing_notes")
                    .delete()
                    .eq("note_id", value: noteId)
                    .execute()
                
                Logger.database.info("✅ Deleted note \(noteId)")
            }
        )
    }
}

// MARK: - Preview Implementation

extension ListingNoteRepositoryClient {
    public static let preview = Self(
        fetchNotes: { _ in
            [ListingNote.mock1, ListingNote.mock2, ListingNote.mock3]
        },
        createNote: { listingId, content in
            ListingNote(
                id: UUID().uuidString,
                listingId: listingId,
                content: content,
                type: .general,
                createdBy: "preview-staff-id",
                createdByName: "Preview User",
                createdAt: Date(),
                updatedAt: Date()
            )
        },
        deleteNote: { _ in }
    )
}
