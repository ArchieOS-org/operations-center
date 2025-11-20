//
//  SyncCoordinator.swift
//  Operations Center
//
//  Coordinates background sync operations with SwiftData
//  Uses @ModelActor for thread-safe access to ModelContext
//

import Foundation
import SwiftData

@ModelActor
actor SyncCoordinator {
    private var activeSyncKeys: Set<String> = []

    /// Check if a sync operation is already running for this key
    func isSyncing(_ key: String) -> Bool {
        activeSyncKeys.contains(key)
    }

    /// Start tracking a sync operation
    /// Throws if sync is already running for this key
    func startSync(_ key: String) throws {
        guard !activeSyncKeys.contains(key) else {
            throw SyncError.alreadySyncing(key: key)
        }
        activeSyncKeys.insert(key)
    }

    /// Complete a sync operation
    func endSync(_ key: String) {
        activeSyncKeys.remove(key)
    }

    /// Cancel all active syncs
    func cancelAll() {
        activeSyncKeys.removeAll()
    }

    // MARK: - Errors

    enum SyncError: Error, LocalizedError {
        case alreadySyncing(key: String)

        var errorDescription: String? {
            switch self {
            case .alreadySyncing(let key):
                return "Sync operation already running for key: \(key)"
            }
        }
    }
}
