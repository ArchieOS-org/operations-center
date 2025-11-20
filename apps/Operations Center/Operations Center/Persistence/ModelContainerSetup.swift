//
//  ModelContainerSetup.swift
//  Operations Center
//
//  Proper ModelContainer setup with explicit directory creation
//  Fixes: "Failed to create file" errors on first launch
//

import Foundation
import SwiftData
import OSLog

extension ModelContainer {
    /// Creates ModelContainer with proper directory setup for Operations Center
    ///
    /// This ensures the Application Support directory exists before SwiftData
    /// tries to create the store, eliminating "Failed to create file" errors
    /// on first launch.
    ///
    /// - Returns: Properly configured ModelContainer with explicit store URL
    /// - Throws: If directory creation or ModelContainer initialization fails
    static func operationsCenterContainer() throws -> ModelContainer {
        Logger.database.info("Setting up ModelContainer with explicit directory...")

        // 1. Get Application Support directory (create if needed)
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true  // Creates directory if missing
        )

        Logger.database.info("Application Support directory: \(appSupportURL.path)")

        // 2. Create app-specific subdirectory
        let storeDirectory = appSupportURL.appendingPathComponent("OperationsCenter")

        // Ensure directory exists with proper permissions
        if !FileManager.default.fileExists(atPath: storeDirectory.path) {
            try FileManager.default.createDirectory(
                at: storeDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            Logger.database.info("Created OperationsCenter directory at: \(storeDirectory.path)")
        } else {
            Logger.database.info("OperationsCenter directory already exists")
        }

        // 3. Define store URL explicitly
        let storeURL = storeDirectory.appendingPathComponent("operations-center.store")
        Logger.database.info("SwiftData store will be at: \(storeURL.path)")

        // 4. Create schema
        let schema = Schema([
            ListingEntity.self,
            ActivityEntity.self,
            ListingNoteEntity.self
        ])

        // 5. Configure with explicit URL
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,  // Explicit URL prevents directory creation errors
            allowsSave: true
        )

        // 6. Return properly configured container
        Logger.database.info("✅ ModelContainer configured successfully")
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
