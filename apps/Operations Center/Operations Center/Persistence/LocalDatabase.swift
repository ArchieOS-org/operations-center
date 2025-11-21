//
//  LocalDatabase.swift
//  Operations Center
//
//  Protocol for local database operations (returns OperationsCenterKit models)
//  SwiftData implementation provides offline-first persistence
//

import Foundation
import SwiftData
import OperationsCenterKit
import OSLog

// MARK: - LocalDatabase Protocol

/// Local database abstraction - returns OperationsCenterKit models, not entities
public protocol LocalDatabase: Sendable {
    // Listings
    func fetchListings() throws -> [Listing]
    func fetchListing(id: String) throws -> Listing?
    func upsertListings(_ listings: [Listing]) throws

    // Activities
    func fetchActivities() throws -> [Activity]
    func upsertActivities(_ activities: [Activity]) throws

    // Notes
    func fetchNotes(for listingId: String) throws -> [ListingNote]
    func upsertNotes(_ notes: [ListingNote]) throws
    func deleteNote(_ noteId: String) throws

    // Staff
    func fetchStaff(byEmail email: String) throws -> Staff?
    func upsertStaff(_ staff: [Staff]) throws
}

// MARK: - SwiftDataLocalDatabase

@MainActor
struct SwiftDataLocalDatabase: LocalDatabase {
    let context: ModelContext

    // MARK: - Listings

    func fetchListings() throws -> [Listing] {
        let descriptor = FetchDescriptor<ListingEntity>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(Listing.init(entity:))
    }

    func fetchListing(id: String) throws -> Listing? {
        let descriptor = FetchDescriptor<ListingEntity>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try context.fetch(descriptor).first.map(Listing.init(entity:))
    }

    func upsertListings(_ listings: [Listing]) throws {
        for listing in listings {
            let descriptor = FetchDescriptor<ListingEntity>(
                predicate: #Predicate { $0.id == listing.id }
            )
            if let existing = try context.fetch(descriptor).first {
                // Update existing entity
                existing.update(from: listing)
            } else {
                // Insert new entity
                context.insert(ListingEntity(from: listing))
            }
        }
        try context.save()
    }

    // MARK: - Activities

    func fetchActivities() throws -> [Activity] {
        let descriptor = FetchDescriptor<ActivityEntity>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(Activity.init(entity:))
    }

    func upsertActivities(_ activities: [Activity]) throws {
        for activity in activities {
            let descriptor = FetchDescriptor<ActivityEntity>(
                predicate: #Predicate { $0.id == activity.id }
            )
            if let existing = try context.fetch(descriptor).first {
                // Update existing entity
                existing.update(from: activity)
            } else {
                // Insert new entity
                context.insert(ActivityEntity(from: activity))
            }
        }
        try context.save()
    }

    // MARK: - Notes

    func fetchNotes(for listingId: String) throws -> [ListingNote] {
        let descriptor = FetchDescriptor<ListingNoteEntity>(
            predicate: #Predicate { $0.listingId == listingId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(ListingNote.init(entity:))
    }

    func upsertNotes(_ notes: [ListingNote]) throws {
        for note in notes {
            let descriptor = FetchDescriptor<ListingNoteEntity>(
                predicate: #Predicate { $0.id == note.id }
            )
            if let existing = try context.fetch(descriptor).first {
                // Update existing entity
                existing.update(from: note)
            } else {
                // Insert new entity
                context.insert(ListingNoteEntity(from: note))
            }
        }
        try context.save()
    }

    func deleteNote(_ noteId: String) throws {
        let descriptor = FetchDescriptor<ListingNoteEntity>(
            predicate: #Predicate { $0.id == noteId }
        )
        if let entity = try context.fetch(descriptor).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Staff

    func fetchStaff(byEmail email: String) throws -> Staff? {
        let descriptor = FetchDescriptor<StaffEntity>(
            predicate: #Predicate { $0.email == email && $0.deletedAt == nil }
        )
        return try context.fetch(descriptor).first.map(Staff.init(entity:))
    }

    func upsertStaff(_ staff: [Staff]) throws {
        for staffMember in staff {
            let descriptor = FetchDescriptor<StaffEntity>(
                predicate: #Predicate { $0.id == staffMember.id }
            )
            if let existing = try context.fetch(descriptor).first {
                // Update existing entity
                existing.update(from: staffMember)
            } else {
                // Insert new entity
                context.insert(StaffEntity(from: staffMember))
            }
        }
        try context.save()
    }
}

// MARK: - PreviewLocalDatabase

/// Preview implementation that returns mock data (no persistence)
struct PreviewLocalDatabase: LocalDatabase {
    func fetchListings() throws -> [Listing] {
        [Listing.mock1, Listing.mock2, Listing.mock3]
    }

    func fetchListing(id: String) throws -> Listing? {
        [Listing.mock1, Listing.mock2, Listing.mock3].first { $0.id == id }
    }

    func upsertListings(_ listings: [Listing]) throws {
        // No-op for previews
    }

    func fetchActivities() throws -> [Activity] {
        [Activity.mock1, Activity.mock2, Activity.mock3]
    }

    func upsertActivities(_ activities: [Activity]) throws {
        // No-op for previews
    }

    func fetchNotes(for listingId: String) throws -> [ListingNote] {
        [ListingNote.mock1, ListingNote.mock2, ListingNote.mock3]
    }

    func upsertNotes(_ notes: [ListingNote]) throws {
        // No-op for previews
    }

    func deleteNote(_ noteId: String) throws {
        // No-op for previews
    }

    func fetchStaff(byEmail email: String) throws -> Staff? {
        // Return mock staff for previews
        return Staff(
            id: "preview-staff-id",
            name: "Preview User",
            email: email,
            phone: nil,
            role: .operations,
            status: "active",
            slackUserId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            metadata: nil
        )
    }

    func upsertStaff(_ staff: [Staff]) throws {
        // No-op for previews
    }
}
