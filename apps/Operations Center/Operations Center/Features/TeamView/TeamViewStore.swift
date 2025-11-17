//
//  TeamViewStore.swift
//  Operations Center
//
//  Protocol for team view stores
//  Eliminates duplication between MarketingTeamStore and AdminTeamStore
//

import Foundation
import OperationsCenterKit

/// Protocol for team view stores
/// Both MarketingTeamStore and AdminTeamStore conform to this
@MainActor
protocol TeamViewStore: Observable {
    var tasks: [TaskWithMessages] { get }
    var activities: [ActivityWithDetails] { get }
    var expandedTaskId: String? { get set }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func loadTasks() async
    func toggleExpansion(for taskId: String)
    func claimTask(_ task: AgentTask) async
    func claimActivity(_ activity: Activity) async
    func deleteTask(_ task: AgentTask) async
    func deleteActivity(_ activity: Activity) async
}
