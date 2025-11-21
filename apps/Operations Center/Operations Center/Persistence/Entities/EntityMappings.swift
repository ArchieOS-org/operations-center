//
//  EntityMappings.swift
//  Operations Center
//
//  Extensions to map from SwiftData entities back to OperationsCenterKit models
//

import Foundation
import OperationsCenterKit

// MARK: - Listing Mapping

extension Listing {
    /// Create Listing DTO from SwiftData entity
    init(entity: ListingEntity) {
        self.init(
            id: entity.id,
            addressString: entity.addressString,
            status: entity.status,
            assignee: entity.assignee,
            realtorId: entity.realtorId,
            dueDate: entity.dueDate,
            progress: entity.progress.map { Decimal($0) },
            type: entity.type,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            completedAt: entity.completedAt,
            deletedAt: entity.deletedAt
        )
    }
}

// MARK: - Activity Mapping

extension Activity {
    /// Create Activity DTO from SwiftData entity
    init(entity: ActivityEntity) {
        self.init(
            id: entity.id,
            listingId: entity.listingId ?? "",  // Activity requires non-optional listingId
            realtorId: entity.realtorId,
            name: entity.name,
            description: entity.detail,
            taskCategory: entity.taskCategoryRaw.flatMap(TaskCategory.init(rawValue:)),
            status: TaskStatus(rawValue: entity.statusRaw) ?? .open,
            priority: entity.priority,
            visibilityGroup: VisibilityGroup(rawValue: entity.visibilityGroupRaw ?? "BOTH") ?? .both,
            assignedStaffId: entity.assignedStaffId,
            dueDate: entity.dueDate,
            claimedAt: entity.claimedAt,
            completedAt: entity.completedAt,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            deletedAt: entity.deletedAt,
            deletedBy: entity.deletedBy,
            inputs: nil,  // JSON blobs not persisted locally yet
            outputs: nil
        )
    }
}

// MARK: - ListingNote Mapping

extension ListingNote {
    /// Create ListingNote DTO from SwiftData entity
    init(entity: ListingNoteEntity) {
        self.init(
            id: entity.id,
            listingId: entity.listingId,
            content: entity.content,
            type: NoteType(rawValue: entity.typeRaw) ?? .general,
            createdBy: entity.createdBy,
            createdByName: entity.createdByName,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
}

// MARK: - Staff Mapping

extension Staff {
    /// Create Staff DTO from SwiftData entity
    init(entity: StaffEntity) {
        self.init(
            id: entity.id,
            name: entity.name,
            email: entity.email,
            phone: entity.phone,
            role: StaffRole(rawValue: entity.roleRaw) ?? .operations,
            status: entity.status,
            slackUserId: entity.slackUserId,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            deletedAt: entity.deletedAt,
            metadata: nil  // Metadata not persisted locally
        )
    }
}
