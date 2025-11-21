//
//  NoteFetchCoalescer.swift
//  Operations Center
//
//  Actor-based request coalescer for note fetching
//  Prevents duplicate simultaneous calls to repository.fetchNotes(listingId)
//  Maintains separate state per listing ID
//

import Foundation
import OperationsCenterKit

/// Coalesces concurrent note fetch requests into a single network call per listing
/// Uses CheckedContinuation pattern for proper cancellation and priority handling
actor NoteFetchCoalescer {
    // MARK: - State

    /// Cache state machine for a single listing's notes
    private enum State {
        case idle
        case fetching([CheckedContinuation<[ListingNote], Error>])
        case cached([ListingNote])
    }

    /// State per listing ID - each listing gets independent coalescing
    private var states: [String: State] = [:]

    // MARK: - Public Interface

    /// Fetch notes for a listing, coalescing concurrent requests
    /// - Parameters:
    ///   - listingId: ID of listing to fetch notes for
    ///   - repository: Repository to use for fetching (only called once per listing per request)
    /// - Returns: Notes (either from in-flight request or fresh fetch)
    /// - Throws: Repository errors (propagated to all waiters)
    func fetch(
        listingId: String,
        using repository: ListingNoteRepositoryClient
    ) async throws -> [ListingNote] {
        let currentState = states[listingId] ?? .idle

        switch currentState {
        case .idle:
            // No request in progress for this listing - start new fetch
            states[listingId] = .fetching([])

            do {
                let notes = try await repository.fetchNotes(listingId)

                // Resume all waiters with success
                resumeWaiters(for: listingId, with: .success(notes))

                // Cache result for subsequent callers
                states[listingId] = .cached(notes)
                return notes
            } catch {
                // Resume all waiters with error
                resumeWaiters(for: listingId, with: .failure(error))

                // Clear state - don't cache errors
                states[listingId] = nil
                throw error
            }

        case .fetching:
            // Request already in progress for this listing - wait for it
            return try await withCheckedThrowingContinuation { continuation in
                guard case .fetching(var continuations) = states[listingId] else {
                    // State changed between check and execution - shouldn't happen
                    continuation.resume(throwing: CancellationError())
                    return
                }

                continuations.append(continuation)
                states[listingId] = .fetching(continuations)
            }

        case .cached(let notes):
            // Result already cached for this listing - return immediately
            return notes
        }
    }

    /// Clear cached result for a specific listing (call when data becomes stale)
    func invalidate(listingId: String) {
        states[listingId] = nil
    }

    /// Clear all cached results (call on logout or full refresh)
    func invalidateAll() {
        states.removeAll()
    }

    // MARK: - Private Helpers

    /// Resume all waiting continuations for a listing with result
    private func resumeWaiters(for listingId: String, with result: Result<[ListingNote], Error>) {
        guard case .fetching(let continuations) = states[listingId] else { return }

        for continuation in continuations {
            continuation.resume(with: result)
        }
    }
}
