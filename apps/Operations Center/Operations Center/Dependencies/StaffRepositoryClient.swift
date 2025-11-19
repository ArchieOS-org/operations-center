//
//  StaffRepositoryClient.swift
//  Operations Center
//
//  Staff repository for lookups and queries
//  Provides single source of truth for staff data access
//

import Dependencies
import Foundation
import OperationsCenterKit
import Supabase

struct StaffRepositoryClient {
    var findById: @Sendable (String) async throws -> Staff?
    var findByEmail: @Sendable (String) async throws -> Staff?
    var listActive: @Sendable () async throws -> [Staff]
}

// MARK: - Dependency Key

extension StaffRepositoryClient: DependencyKey {
    static let liveValue: Self = {
        return Self(
            findById: { staffId in
                try await supabase
                    .from("staff")
                    .select()
                    .eq("staff_id", value: staffId)
                    .is("deleted_at", value: nil)
                    .single()
                    .execute()
                    .value
            },
            findByEmail: { email in
                try await supabase
                    .from("staff")
                    .select()
                    .eq("email", value: email)
                    .is("deleted_at", value: nil)
                    .single()
                    .execute()
                    .value
            },
            listActive: {
                try await supabase
                    .from("staff")
                    .select()
                    .eq("status", value: "active")
                    .is("deleted_at", value: nil)
                    .order("name")
                    .execute()
                    .value
            }
        )
    }()

    static let testValue = Self(
        findById: { _ in nil },
        findByEmail: { _ in nil },
        listActive: { [] }
    )
}

extension DependencyValues {
    var staffRepository: StaffRepositoryClient {
        get { self[StaffRepositoryClient.self] }
        set { self[StaffRepositoryClient.self] = newValue }
    }
}
