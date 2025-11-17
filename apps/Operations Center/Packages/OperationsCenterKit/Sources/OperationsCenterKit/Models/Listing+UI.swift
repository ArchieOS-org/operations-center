//
//  Listing+UI.swift
//  OperationsCenterKit
//
//  View-layer extensions for Listing models
//  Keeps UI concerns separate from data models
//

import SwiftUI

// MARK: - ListingStatus UI Extensions

extension ListingStatus {
    /// Resolved color for this status (design token)
    /// Maps semantic color name to actual Color via design system
    public var color: Color {
        Colors.semantic(semanticColorName)
    }
}
