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
import OSLog
import Supabase

struct StaffRepositoryClient {
    var findById: @Sendable (String) async throws -> Staff?
    var findByEmail: @Sendable (String) async throws -> Staff?
    var listActive: @Sendable () async throws -> [Staff]
}

// MARK: - Dependency Key

extension StaffRepositoryClient: DependencyKey {
    static func live(localDatabase: LocalDatabase) -> Self {
        return Self(
            findById: { staffId in
                // Read from local database first
                if let cached = try? await MainActor.run({ try localDatabase.fetchStaff(byEmail: "") }) {
                    // Note: This is a placeholder - we'd need fetchStaff(byId:) method
                    // For now, fall through to Supabase
                }
                
                // Fetch from Supabase
                let staff = try await supabase
                    .from("staff")
                    .select()
                    .eq("staff_id", value: staffId)
                    .is("deleted_at", value: nil)
                    .single()
                    .execute()
                    .value
                
                // Save to local database
                try? await MainActor.run { try localDatabase.upsertStaff([staff]) }
                
                return staff
            },
            findByEmail: { email in
                Logger.database.info("🔍 [StaffRepository] Looking up staff by email: \(email)")
                
                // Read from local database first (instant lookup)
                if let cached = try? await MainActor.run({ try localDatabase.fetchStaff(byEmail: email) }) {
                    Logger.database.info("✅ [StaffRepository] Found staff in local cache: \(cached.name)")
                    // Background refresh from Supabase
                    Task.detached {
                        do {
                            let staff = try await supabase
                                .from("staff")
                                .select()
                                .eq("email", value: email)
                                .is("deleted_at", value: nil)
                                .single()
                                .execute()
                                .value
                            
                            try await MainActor.run { try localDatabase.upsertStaff([staff]) }
                            Logger.database.info("🔄 [StaffRepository] Background refresh completed for \(email)")
                        } catch {
                            // Silent failure - cached data is fine
                            Logger.database.error("⚠️ [StaffRepository] Background refresh failed: \(error.localizedDescription)")
                        }
                    }
                    return cached
                }
                
                Logger.database.info("❌ [StaffRepository] Staff not in local cache, fetching from Supabase...")
                // Not in cache - fetch from Supabase
                let staff = try await supabase
                    .from("staff")
                    .select()
                    .eq("email", value: email)
                    .is("deleted_at", value: nil)
                    .single()
                    .execute()
                    .value
                
                Logger.database.info("✅ [StaffRepository] Fetched staff from Supabase: \(staff.name)")
                
                // Save to local database
                try await MainActor.run { try localDatabase.upsertStaff([staff]) }
                Logger.database.info("💾 [StaffRepository] Saved staff to local database")
                
                return staff
            },
            listActive: {
                // Always fetch fresh from Supabase for list operations
                // (could add local caching later if needed)
                let staff = try await supabase
                    .from("staff")
                    .select()
                    .eq("status", value: "active")
                    .is("deleted_at", value: nil)
                    .order("name")
                    .execute()
                    .value
                
                // Save to local database
                try await MainActor.run { try localDatabase.upsertStaff(staff) }
                
                return staff
            }
        )
    }
    
    static let liveValue: Self = {
        // This will be replaced with live(localDatabase:) in app initialization
        return Self(
            findById: { _ in nil },
            findByEmail: { _ in nil },
            listActive: { [] }
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
