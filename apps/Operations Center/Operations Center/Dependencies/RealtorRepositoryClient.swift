//
//  RealtorRepositoryClient.swift
//  Operations Center
//
//  Realtor repository client using native Swift patterns
//

import Foundation
import OperationsCenterKit
import OSLog
import Supabase

// MARK: - Realtor Repository Client

/// Realtor repository client for production and preview contexts
public struct RealtorRepositoryClient {
    /// Fetch all active realtors/agents
    public var fetchRealtors: @Sendable () async throws -> [Realtor]

    /// Fetch a specific realtor by ID
    public var fetchRealtor: @Sendable (_ realtorId: String) async throws -> Realtor?
}

// MARK: - Live Implementation

extension RealtorRepositoryClient {
    /// Production implementation using global Supabase client
    public static let live = Self(
        fetchRealtors: {
            Logger.database.info("Fetching all active realtors")

            let realtors: [Realtor] = try await supabase
                .from("realtors")
                .select()
                .is("deleted_at", value: nil)
                .eq("status", value: "active")
                .order("name", ascending: true)
                .execute()
                .value

            Logger.database.info("Fetched \(realtors.count) active realtors")
            return realtors
        },
        fetchRealtor: { realtorId in
            Logger.database.info("Fetching realtor: \(realtorId)")

            let realtors: [Realtor] = try await supabase
                .from("realtors")
                .select()
                .eq("realtor_id", value: realtorId)
                .is("deleted_at", value: nil)
                .execute()
                .value

            return realtors.first
        }
    )
}

// MARK: - Preview Implementation

extension RealtorRepositoryClient {
    /// Preview implementation using mock data
    public static let preview = Self(
        fetchRealtors: {
            Logger.database.info("Using preview data for realtors")
            // Simulate network delay
            try? await Task.sleep(for: .milliseconds(500))
            return Realtor.mockList
        },
        fetchRealtor: { realtorId in
            Logger.database.info("Using preview data for realtor: \(realtorId)")
            // Simulate network delay
            try? await Task.sleep(for: .milliseconds(300))
            return Realtor.mockList.first { $0.id == realtorId }
        }
    )
}
