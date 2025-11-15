//
//  Logger+Categories.swift
//  Operations Center
//
//  Structured logging infrastructure using Apple's OSLog framework.
//  Zero performance overhead in release builds, automatic privacy handling.
//

import OSLog

extension Logger {
    /// Subsystem identifier for all Operations Center logs
    private nonisolated(unsafe) static let subsystem = Bundle.main.bundleIdentifier ?? "com.operations-center"

    /// Task operations: fetch, claim, delete, complete
    nonisolated(unsafe) static let tasks = Logger(subsystem: subsystem, category: "tasks")

    /// Database operations: queries, mutations, cache
    nonisolated(unsafe) static let database = Logger(subsystem: subsystem, category: "database")

    /// UI events: navigation, user interactions, view lifecycle
    nonisolated(unsafe) static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Network operations: requests, responses, errors
    nonisolated(unsafe) static let network = Logger(subsystem: subsystem, category: "network")

    /// Performance metrics: timing, memory, responsiveness
    nonisolated(unsafe) static let performance = Logger(subsystem: subsystem, category: "performance")
}
