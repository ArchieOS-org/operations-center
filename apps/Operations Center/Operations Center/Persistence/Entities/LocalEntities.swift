//
//  LocalEntities.swift
//  Operations Center
//
//  SwiftData entity models for local-first offline sync
//  Maps from OperationsCenterKit models (Codable DTOs) to SwiftData persistence
//

import Foundation
import SwiftData
import OperationsCenterKit

// MARK: - ListingEntity

@Model
final class ListingEntity {
    @Attribute(.unique) var id: String
    var addressString: String
    var status: String
    var assignee: String?
    var realtorId: String?
    var dueDate: Date?
    var progress: Double?
    var type: String?

    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var deletedAt: Date?

    // Sync metadata
    var syncedAt: Date?
    var isDirty: Bool

    init(from listing: Listing) {
        self.id = listing.id
        self.addressString = listing.addressString
        self.status = listing.status
        self.assignee = listing.assignee
        self.realtorId = listing.realtorId
        self.dueDate = listing.dueDate
        self.progress = listing.progress.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.type = listing.type
        self.createdAt = listing.createdAt
        self.updatedAt = listing.updatedAt
        self.completedAt = listing.completedAt
        self.deletedAt = listing.deletedAt
        self.syncedAt = nil
        self.isDirty = false
    }

    /// Update entity from DTO (for upsert operations)
    func update(from listing: Listing) {
        self.addressString = listing.addressString
        self.status = listing.status
        self.assignee = listing.assignee
        self.realtorId = listing.realtorId
        self.dueDate = listing.dueDate
        self.progress = listing.progress.map { NSDecimalNumber(decimal: $0).doubleValue }
        self.type = listing.type
        self.updatedAt = listing.updatedAt
        self.completedAt = listing.completedAt
        self.deletedAt = listing.deletedAt
        self.syncedAt = Date()
        // Don't clear isDirty - preserve local changes flag
    }
}

// MARK: - ActivityEntity

@Model
final class ActivityEntity {
    @Attribute(.unique) var id: String
    var listingId: String?
    var realtorId: String?
    var name: String
    var detail: String?  // maps from Activity.description
    var taskCategoryRaw: String?
    var statusRaw: String
    var priority: Int
    var visibilityGroupRaw: String?
    var assignedStaffId: String?
    var dueDate: Date?
    var claimedAt: Date?
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var deletedBy: String?

    // Sync metadata
    var syncedAt: Date?
    var isDirty: Bool

    init(from activity: Activity) {
        self.id = activity.id
        self.listingId = activity.listingId
        self.realtorId = activity.realtorId
        self.name = activity.name
        self.detail = activity.description
        self.taskCategoryRaw = activity.taskCategory?.rawValue
        self.statusRaw = activity.status.rawValue
        self.priority = activity.priority
        self.visibilityGroupRaw = activity.visibilityGroup.rawValue
        self.assignedStaffId = activity.assignedStaffId
        self.dueDate = activity.dueDate
        self.claimedAt = activity.claimedAt
        self.completedAt = activity.completedAt
        self.createdAt = activity.createdAt
        self.updatedAt = activity.updatedAt
        self.deletedAt = activity.deletedAt
        self.deletedBy = activity.deletedBy
        self.syncedAt = nil
        self.isDirty = false
    }

    /// Update entity from DTO (for upsert operations)
    func update(from activity: Activity) {
        self.listingId = activity.listingId
        self.realtorId = activity.realtorId
        self.name = activity.name
        self.detail = activity.description
        self.taskCategoryRaw = activity.taskCategory?.rawValue
        self.statusRaw = activity.status.rawValue
        self.priority = activity.priority
        self.visibilityGroupRaw = activity.visibilityGroup.rawValue
        self.assignedStaffId = activity.assignedStaffId
        self.dueDate = activity.dueDate
        self.claimedAt = activity.claimedAt
        self.completedAt = activity.completedAt
        self.updatedAt = activity.updatedAt
        self.deletedAt = activity.deletedAt
        self.deletedBy = activity.deletedBy
        self.syncedAt = Date()
        // Don't clear isDirty - preserve local changes flag
    }
}

// MARK: - ListingNoteEntity

@Model
final class ListingNoteEntity {
    @Attribute(.unique) var id: String
    var listingId: String
    var content: String
    var typeRaw: String
    var createdBy: String?
    var createdByName: String?
    var createdAt: Date
    var updatedAt: Date

    // Sync metadata
    var syncedAt: Date?
    var isDirty: Bool

    init(from note: ListingNote) {
        self.id = note.id
        self.listingId = note.listingId
        self.content = note.content
        self.typeRaw = note.type.rawValue
        self.createdBy = note.createdBy
        self.createdByName = note.createdByName
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
        self.syncedAt = nil
        self.isDirty = false
    }

    /// Update entity from DTO (for upsert operations)
    func update(from note: ListingNote) {
        self.content = note.content
        self.typeRaw = note.type.rawValue
        self.createdBy = note.createdBy
        self.createdByName = note.createdByName
        self.updatedAt = note.updatedAt
        self.syncedAt = Date()
        // Don't clear isDirty - preserve local changes flag
    }
}
