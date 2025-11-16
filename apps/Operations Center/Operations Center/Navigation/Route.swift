//
//  Route.swift
//  Operations Center
//
//  Navigation routes for Things 3-style hierarchy
//

import Foundation

/// Navigation routes following Things 3 pattern
enum Route: Hashable, Identifiable {
    case inbox
    case myTasks
    case myListings
    case logbook
    case agents
    case agent(id: String)
    case listing(id: String)
    case allTasks
    case allListings
    case settings

    var id: String {
        switch self {
        case .inbox: return "inbox"
        case .myTasks: return "myTasks"
        case .myListings: return "myListings"
        case .logbook: return "logbook"
        case .agents: return "agents"
        case .agent(let id): return "agent-\(id)"
        case .listing(let id): return "listing-\(id)"
        case .allTasks: return "allTasks"
        case .allListings: return "allListings"
        case .settings: return "settings"
        }
    }

    var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .myTasks: return "My Tasks"
        case .myListings: return "My Listings"
        case .logbook: return "Logbook"
        case .agents: return "Agents"
        case .agent: return "Agent"
        case .listing: return "Listing"
        case .allTasks: return "All Tasks"
        case .allListings: return "All Listings"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .myTasks: return "checkmark.circle.fill"
        case .myListings: return "house.fill"
        case .logbook: return "clock.fill"
        case .agents: return "person.2.fill"
        case .agent: return "person.fill"
        case .listing: return "building.2.fill"
        case .allTasks: return "list.bullet"
        case .allListings: return "building.2"
        case .settings: return "gearshape.fill"
        }
    }
}
