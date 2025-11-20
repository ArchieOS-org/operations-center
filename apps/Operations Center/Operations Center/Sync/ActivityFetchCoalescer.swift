//
//  ActivityFetchCoalescer.swift
//  Operations Center
//
//  Actor-based request coalescer for activity fetching
//  Prevents duplicate simultaneous calls to repository.fetchActivities()
//

import Foundation
import OperationsCenterKit

/// Coalesces concurrent activity fetch requests into a single network call
/// Uses CheckedContinuation pattern for proper cancellation and priority handling
actor ActivityFetchCoalescer {
    // MARK: - State

    /// Cache state machine - idle, fetching with waiters, or cached result
    private enum State {
        case idle
        case fetching([CheckedContinuation<[ActivityWithDetails], Error>])
        case cached([ActivityWithDetails])
    }

    private var state: State = .idle

    // MARK: - Public Interface

    /// Fetch activities, coalescing concurrent requests
    /// - Parameter repository: Repository to use for fetching (only called once per request)
    /// - Returns: Activities (either from in-flight request or fresh fetch)
    /// - Throws: Repository errors (propagated to all waiters)
    func fetch(using repository: TaskRepositoryClient) async throws -> [ActivityWithDetails] {
        switch state {
        case .idle:
            // No request in progress - start new fetch
            state = .fetching([])

            do {
                let activities = try await repository.fetchActivities()

                // Resume all waiters with success
                resumeWaiters(with: .success(activities))

                // Cache result for subsequent callers
                state = .cached(activities)
                return activities
            } catch {
                // Resume all waiters with error
                resumeWaiters(with: .failure(error))

                // Clear state - don't cache errors
                state = .idle
                throw error
            }

        case .fetching:
            // Request already in progress - wait for it
            return try await withCheckedThrowingContinuation { continuation in
                guard case .fetching(var continuations) = state else {
                    // State changed between check and execution - shouldn't happen
                    continuation.resume(throwing: CancellationError())
                    return
                }

                continuations.append(continuation)
                state = .fetching(continuations)
            }

        case .cached(let activities):
            // Result already cached - return immediately
            return activities
        }
    }

    /// Clear cached result (call when data becomes stale)
    func invalidate() {
        state = .idle
    }

    // MARK: - Private Helpers

    /// Resume all waiting continuations with result
    private func resumeWaiters(with result: Result<[ActivityWithDetails], Error>) {
        guard case .fetching(let continuations) = state else { return }

        for continuation in continuations {
            continuation.resume(with: result)
        }
    }
}
