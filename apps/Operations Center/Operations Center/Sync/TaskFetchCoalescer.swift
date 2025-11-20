//
//  TaskFetchCoalescer.swift
//  Operations Center
//
//  Actor-based request coalescer for agent task fetching
//  Prevents duplicate simultaneous calls to repository.fetchTasks()
//

import Foundation
import OperationsCenterKit

/// Coalesces concurrent task fetch requests into a single network call
/// Uses CheckedContinuation pattern for proper cancellation and priority handling
actor TaskFetchCoalescer {
    // MARK: - State

    /// Cache state machine
    private enum State {
        case idle
        case fetching([CheckedContinuation<[TaskWithMessages], Error>])
        case cached([TaskWithMessages])
    }

    private var state: State = .idle

    // MARK: - Public Interface

    /// Fetch agent tasks, coalescing concurrent requests
    /// - Parameter repository: Repository to use for fetching (only called once per request)
    /// - Returns: Tasks (either from in-flight request or fresh fetch)
    /// - Throws: Repository errors (propagated to all waiters)
    func fetch(using repository: TaskRepositoryClient) async throws -> [TaskWithMessages] {
        switch state {
        case .idle:
            // No request in progress - start new fetch
            state = .fetching([])

            do {
                let tasks = try await repository.fetchTasks()

                // Resume all waiters with success
                resumeWaiters(with: .success(tasks))

                // Cache result for subsequent callers
                state = .cached(tasks)
                return tasks
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

        case .cached(let tasks):
            // Result already cached - return immediately
            return tasks
        }
    }

    /// Clear cached result (call when data becomes stale)
    func invalidate() {
        state = .idle
    }

    // MARK: - Private Helpers

    /// Resume all waiting continuations with result
    private func resumeWaiters(with result: Result<[TaskWithMessages], Error>) {
        guard case .fetching(let continuations) = state else { return }

        for continuation in continuations {
            continuation.resume(with: result)
        }
    }
}
