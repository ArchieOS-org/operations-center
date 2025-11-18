# Type Safety Audit - Code Examples and Fixes

## Issue 1: String Type Fields (ListingNote)

### Current (Weak):
```swift
// ListingNote.swift
public struct ListingNote: Identifiable, Codable, Sendable {
    public let type: String  // ❌ No validation
    
    public init(
        // ...
        type: String = "general",  // ❌ Magic string
        // ...
    ) { }
}

// Usage in views:
if note.type == "general" { }  // ❌ Typo creates new type
```

### Fixed (Strong):
```swift
// ListingNote.swift
public enum NoteType: String, Codable, Sendable {
    case general
    case inspection
    case realtor
    case other
    
    public var displayName: String {
        switch self {
        case .general: return "General"
        case .inspection: return "Inspection"
        case .realtor: return "Realtor Note"
        case .other: return "Other"
        }
    }
}

public struct ListingNote: Identifiable, Codable, Sendable {
    public let type: NoteType  // ✓ Strongly typed
    
    public init(
        // ...
        type: NoteType = .general,  // ✓ No magic strings
        // ...
    ) { }
}

// Usage in views:
if note.type == .general { }  // ✓ Compiler catches typos
```

---

## Issue 2: String Status in Listing Model

### Current (Weak):
```swift
// Listing.swift
public struct Listing: Identifiable, Codable, Sendable {
    public let status: String  // ❌ Raw string
    public let type: String?   // ❌ Raw string
    
    // CodingKeys map snake_case from database
    enum CodingKeys: String, CodingKey {
        case status  // Database: "ACTIVE", "PENDING", "COMPLETED"
        case type    // Database: "SALE", "RENTAL", "COMMERCIAL"
    }
}

// In stores:
listings = listings.filter { $0.status == "ACTIVE" }  // ❌ Typo breaks silently
```

### Fixed (Strong):
```swift
// Listing.swift
public enum ListingStatus: String, Codable, Sendable {
    case active = "ACTIVE"
    case pending = "PENDING"
    case completed = "COMPLETED"
    
    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .pending: return "Pending"
        case .completed: return "Completed"
        }
    }
}

public enum ListingType: String, Codable, Sendable {
    case sale = "SALE"
    case rental = "RENTAL"
    case commercial = "COMMERCIAL"
    case residential = "RESIDENTIAL"
}

public struct Listing: Identifiable, Codable, Sendable {
    public let status: ListingStatus  // ✓ Strongly typed
    public let type: ListingType?     // ✓ Strongly typed
}

// In stores:
listings = listings.filter { $0.status == .active }  // ✓ Compiler enforces
```

---

## Issue 3: AnyCodable Type Erasure

### Current (Weak):
```swift
// Activity.swift
public struct Activity: Identifiable, Codable, Sendable {
    public let inputs: [String: AnyCodable]?   // ❌ Type erasure
    public let outputs: [String: AnyCodable]?  // ❌ Type erasure
}

// Usage:
let activity = fetchActivity()
if let budget = activity.inputs?["budget"].value as? Int {  // ❌ Runtime casting
    print("Budget: \(budget)")
}

// If "budget" is actually a string or missing:
// Result: Silent failure or crash
```

### Fixed (Strong):
```swift
// Activity.swift
public struct ActivityInputs: Codable, Sendable {
    public let photographer: String?
    public let budget: Int?
    public let platforms: [String]?
    public let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case photographer
        case budget
        case platforms
        case notes
    }
}

public struct ActivityOutputs: Codable, Sendable {
    public let photoCount: Int?
    public let platforms: [String]?
    public let completedAt: Date?
}

public struct Activity: Identifiable, Codable, Sendable {
    public let inputs: ActivityInputs?   // ✓ Strongly typed
    public let outputs: ActivityOutputs? // ✓ Strongly typed
}

// Usage:
let activity = fetchActivity()
if let budget = activity.inputs?.budget {  // ✓ No casting, compiler knows type
    print("Budget: \(budget)")  // ✓ Guaranteed Int or nil
}
```

---

## Issue 4: Silent Enum Fallbacks

### Current (Weak):
```swift
// TaskRepositoryClient.swift
nonisolated private func mapActivityResponse(_ row: ActivityResponse) -> ActivityWithDetails? {
    let task = Activity(
        // ...
        status: Activity.TaskStatus(rawValue: row.status) ?? .open,  // ❌ Silent fallback
        visibilityGroup: Activity.VisibilityGroup(rawValue: row.visibilityGroup) ?? .both,
        // ...
    )
}

// If database returns:
// status: "INVALID_STATUS"
// Result: Silently treated as .open
// No logging, no error, silent data loss
```

### Fixed (Strong):
```swift
// TaskRepositoryClient.swift
enum MappingError: LocalizedError {
    case invalidStatus(String)
    case invalidVisibilityGroup(String)
    case missingListing
    
    var errorDescription: String? {
        switch self {
        case .invalidStatus(let value):
            return "Database returned invalid status: \(value)"
        case .invalidVisibilityGroup(let value):
            return "Database returned invalid visibility group: \(value)"
        case .missingListing:
            return "Activity has no associated listing"
        }
    }
}

nonisolated private func mapActivityResponse(_ row: ActivityResponse) throws -> ActivityWithDetails {
    guard let listing = row.listing else {
        throw MappingError.missingListing
    }
    
    guard let status = Activity.TaskStatus(rawValue: row.status) else {
        throw MappingError.invalidStatus(row.status)  // ✓ Explicit error
    }
    
    guard let visibilityGroup = Activity.VisibilityGroup(rawValue: row.visibilityGroup) else {
        throw MappingError.invalidVisibilityGroup(row.visibilityGroup)  // ✓ Explicit error
    }
    
    let task = Activity(
        // ...
        status: status,
        visibilityGroup: visibilityGroup,
        // ...
    )
    
    return ActivityWithDetails(task: task, listing: listing)
}
```

---

## Issue 5: Duplicate Enums (DRY Violation)

### Current (Weak):
```swift
// Activity.swift
public enum TaskStatus: String, Codable, Sendable {
    case open = "OPEN"
    case claimed = "CLAIMED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}

// AgentTask.swift
public enum TaskStatus: String, Codable, Sendable {
    case open = "OPEN"
    case claimed = "CLAIMED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}

// ❌ If you change one, system breaks
// ❌ Different enum types can't be compared
```

### Fixed (Strong):
```swift
// TaskStatus.swift (new file)
public enum TaskStatus: String, Codable, Sendable {
    case open = "OPEN"
    case claimed = "CLAIMED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    
    public var displayName: String {
        switch self {
        case .open: return "Open"
        case .claimed: return "Claimed"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var isActive: Bool {
        self != .done && self != .failed && self != .cancelled
    }
}

// Activity.swift
public struct Activity: Identifiable, Codable, Sendable {
    public let status: TaskStatus  // ✓ Shared enum
}

// AgentTask.swift
public struct AgentTask: Identifiable, Codable, Sendable {
    public let status: TaskStatus  // ✓ Shared enum
}

// ✓ Single source of truth
// ✓ Changes in one place
// ✓ Both types now compatible
```

---

## Issue 6: String IDs Allow Mixing

### Current (Weak):
```swift
// Models use plain String for IDs
public struct Activity {
    public let id: String
    public let listingId: String
    public let assignedStaffId: String?
}

public struct Listing {
    public let id: String
}

// Accidental mixing:
activity.assignedStaffId = listing.id  // ❌ Compiles but wrong!
// Result: Task assigned to wrong entity, silent data corruption
```

### Fixed (Strong):
```swift
// ID types
public typealias ActivityId = String
public typealias ListingId = String
public typealias StaffId = String
public typealias UserId = String

// Models use specific types
public struct Activity {
    public let id: ActivityId        // ✓ Specific type
    public let listingId: ListingId  // ✓ Specific type
    public let assignedStaffId: StaffId?  // ✓ Specific type
}

public struct Listing {
    public let id: ListingId  // ✓ Specific type
}

// Type checking prevents mixing:
activity.assignedStaffId = listing.id  // ❌ Compiler error!
// error: cannot assign value of type 'ListingId' to type 'StaffId?'

// Force explicit conversions when needed:
activity.assignedStaffId = StaffId(listing.id)  // ✓ Intentional, flagged in code review
```

---

## Issue 7: Missing Auditable Protocol

### Current (Weak):
```swift
// Every model duplicates audit fields
public struct Activity {
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let deletedBy: String?
}

public struct AgentTask {
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let deletedBy: String?
}

public struct Listing {
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?
    public let deletedAt: Date?
}

// ❌ No way to write generic soft-delete function
// ❌ No way to validate timestamps
// ❌ Code duplication across models
```

### Fixed (Strong):
```swift
// Shared protocol
public protocol Auditable: Identifiable, Codable, Sendable {
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var deletedAt: Date? { get }
    var deletedBy: String? { get }
    
    var isDeleted: Bool { get }
    var isDeletionValid: Bool { get }
}

// Default implementations
extension Auditable {
    public var isDeleted: Bool {
        deletedAt != nil
    }
    
    public var isDeletionValid: Bool {
        // Ensure both or neither are set
        (deletedAt != nil && deletedBy != nil) ||
        (deletedAt == nil && deletedBy == nil)
    }
}

// Models conform
public struct Activity: Auditable {
    public let id: String
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let deletedBy: String?
    // ...
}

// Generic soft-delete operation
func softDelete<T: Auditable>(_ item: T, by userId: String) throws -> T {
    var updated = item
    let now = Date()
    
    // Updates using withUpdated helper or copyWithDelete method
    // (requires making models either classes or adding update methods)
    
    return updated
}

// Audit trail validation
func validateAuditTrail<T: Auditable>(_ items: [T]) -> [ValidationError] {
    items.compactMap { item in
        if !item.isDeletionValid {
            return ValidationError.invalidDeletionState(itemId: item.id)
        }
        return nil
    }
}
```

---

## Issue 8: Mutable Structs (Should Be Immutable)

### Current (Weak):
```swift
// Activity is a struct but has mutable properties
public struct Activity: Identifiable, Codable, Sendable {
    public var status: TaskStatus           // ❌ Mutable!
    public var assignedStaffId: String?     // ❌ Mutable!
    public var claimedAt: Date?             // ❌ Mutable!
}

// Allows accidental mutation:
var activity = fetchActivity()
activity.status = .invalid        // Compiles! But violates invariants
activity.assignedStaffId = ""     // Compiles! Invalid state
activity.claimedAt = .now         // Compiles! Inconsistent with status
```

### Fixed (Strong):
```swift
public struct Activity: Identifiable, Codable, Sendable {
    // All properties immutable
    public let id: String
    public let status: TaskStatus          // ✓ Immutable
    public let assignedStaffId: String?    // ✓ Immutable
    public let claimedAt: Date?            // ✓ Immutable
    // ...
    
    // Explicit update methods for needed changes
    func withStatus(_ newStatus: TaskStatus) -> Activity {
        var copy = self
        copy.status = newStatus
        return copy
    }
    
    func claimed(by staffId: String) -> Activity {
        var copy = self
        copy.status = .claimed
        copy.assignedStaffId = staffId
        copy.claimedAt = Date()
        return copy
    }
}

// Usage enforces intentional changes:
let activity = fetchActivity()
let updated = activity.claimed(by: userId)  // ✓ Explicit, flagged in diffs
```

---

## Issue 9: String Color Names Not Validated

### Current (Weak):
```swift
// Colors.swift
public static func semantic(_ name: String) -> Color {
    switch name {
    case "success": return statusCompleted
    case "warning": return statusClaimed
    case "info": return statusInProgress
    case "error": return statusFailed
    case "neutral": return statusCancelled
    default: return Color.gray  // ❌ Silent fallback
    }
}

// Usage allows typos:
let color = Colors.semantic("succes")  // ❌ Typo, falls back to gray silently
```

### Fixed (Strong):
```swift
// Colors.swift
public enum SemanticColorRole: String, CaseIterable, Sendable {
    case success
    case warning
    case info
    case error
    case neutral
    
    public var displayName: String {
        rawValue.capitalized
    }
}

public static func semantic(_ role: SemanticColorRole) -> Color {
    switch role {
    case .success: return statusCompleted
    case .warning: return statusClaimed
    case .info: return statusInProgress
    case .error: return statusFailed
    case .neutral: return statusCancelled
    }
}

// Usage enforces valid colors:
let color = Colors.semantic(.success)  // ✓ Compiler checks
let color = Colors.semantic(.succes)   // ❌ Compiler error!
```

---

## Issue 10: String Filter Operators Not Validated

### Current (Weak):
```swift
// TaskRepositoryClient.swift
let tasks: [AgentTask] = try await supabase
    .from("agent_tasks")
    .select()
    .filter("deleted_at", operator: "not.is.null", value: "")  // ❌ String operator
    .order("deleted_at", ascending: false)
    .execute()
    .value

// Typos in operator:
.filter("deleted_at", operator: "not.is.null", value: "")  // ✓ Works
.filter("deleted_at", operator: "not.is.nul", value: "")   // ❌ Silent failure
```

### Fixed (Strong):
```swift
// QueryBuilder.swift
enum FilterOperator: String {
    case isNull = "is.null"
    case notIsNull = "not.is.null"
    case equals = "eq"
    case notEquals = "neq"
    case greaterThan = "gt"
    case lessThan = "lt"
}

extension SupabaseQueryBuilder {
    func filter(_ column: String, operator: FilterOperator, value: String = "") {
        // Use enum instead of string
        filter(column, operator: operator.rawValue, value: value)
    }
}

// TaskRepositoryClient.swift
let tasks: [AgentTask] = try await supabase
    .from("agent_tasks")
    .select()
    .filter("deleted_at", operator: .notIsNull)  // ✓ Compiler checked
    .order("deleted_at", ascending: false)
    .execute()
    .value

// Typos caught at compile time:
.filter("deleted_at", operator: .notIsNul)  // ❌ Compiler error!
```

---

## Summary: Pattern to Fix All Issues

Every time you see:
- A `String` for something with discrete values → Use `enum`
- An `Any` type → Use a concrete struct or generic
- A `??` fallback → Throw an error instead
- A duplicated enum → Extract to shared file
- A `String` ID being compared → Use `typealias`

Fix: Type system exists for a reason. Use it.

