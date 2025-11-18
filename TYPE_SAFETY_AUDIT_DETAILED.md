TYPE SAFETY AUDIT - Operations Center Swift App
===============================================

COMPREHENSIVE ANALYSIS OF 104 SWIFT FILES

1. CRITICAL TYPE SAFETY ISSUES
=============================

Issue 1.1: String-Based Type Fields (STRINGLY TYPED)
----------------------------------------------------
Location: ListingNote.swift
Problem:
  public let type: String  // Should be enum
  public let type: String = "general"  // Hardcoded string

This should be:
  enum NoteType: String, Codable { case general, other ... }

Impact: No compile-time guarantees for valid types. Misspellings silently allowed.
Instances Found: 1 critical file

Issue 1.2: String-Based Status Field in Listing Model
-----------------------------------------------------
Location: Listing.swift (lines 63, 81)
Problem:
  public let status: String  // Raw string, not enum
  public let type: String?   // Raw string, not enum

These should be strongly typed enums:
  public let status: ListingStatus
  public let type: ListingType

Current pattern bypasses the compiler's enum enforcement:
  // Current (weak):
  if listing.status == "ACTIVE" { ... }
  
  // Should be:
  if listing.status == .active { ... }

Impact: Allows invalid strings to flow through system. No exhaustiveness checking.
Status is cast at runtime using: ListingStatus(rawValue: status.uppercased())

Issue 1.3: String Comparison Fallback Pattern
---------------------------------------------
Location: Activity.swift, TaskRepositoryClient.swift
Problem:
  // In mapActivityResponse (line 121)
  status: Activity.TaskStatus(rawValue: row.status) ?? .open

The fallback to .open masks invalid database values silently.
No error thrown if database contains unexpected status values.

Issue 1.4: Metadata Uses AnyCodable for Arbitrary JSON
------------------------------------------------------
Location: Activity.swift (lines 28-29, 82-83), Realtor.swift (line 28)
Problem:
  public let inputs: [String: AnyCodable]?
  public let outputs: [String: AnyCodable]?
  public let metadata: [String: AnyCodable]?

Using `Any` (wrapped as AnyCodable) loses type information:
  - No IDE autocomplete for keys
  - Runtime type casting required to use values
  - Invalid keys silently ignored
  - Type mismatches not caught until runtime

Current usage (Activity.swift mock):
  inputs: ["photographer": AnyCodable("John Smith Photography")]
  inputs: ["budget": AnyCodable(500), "platforms": AnyCodable(["instagram", "facebook"])]

Better approach: Use strongly typed structs:
  struct ActivityInputs: Codable {
    var photographer: String?
    var budget: Int?
    var platforms: [String]?
  }

Impact: 16 usages of AnyCodable. Each is a type safety escape hatch.
Instances Found: 16 files/usages

2. MISSED PROTOCOL OPPORTUNITIES
================================

Issue 2.1: No Consistent Model Protocol
---------------------------------------
Location: All model files lack a common interface
Problem:
  Models (Activity, AgentTask, Listing, Staff) are Identifiable + Codable + Sendable
  But no shared protocol defines minimum requirements

Missed opportunity:
  protocol Auditable: Identifiable, Sendable {
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var deletedAt: Date? { get }
    var deletedBy: String? { get }
  }

This would enable:
  - Generic soft-delete operations
  - Type-safe audit trail functions
  - Automatic timestamp validation

Issue 2.2: Repository Protocol Too Minimal
------------------------------------------
Location: TaskRepository.swift
Problem:
  Only defines fetch/claim/delete operations
  No generic protocol for common patterns across repositories

Would benefit from:
  protocol CRUDRepository: Sendable {
    associatedtype Entity: Identifiable & Codable
    func fetch(_ id: String) async throws -> Entity
    func list() async throws -> [Entity]
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(_ id: String) async throws -> Void
  }

This would make task, listing, and note repositories consistent.

Issue 2.3: No Error Type Protocol
---------------------------------
Location: AuthenticationStore.swift
Problem:
  AuthError enum defined locally in AuthenticationStore
  Should be shared with other error scenarios

Missing protocol:
  protocol DomainError: LocalizedError, Equatable {
    associatedtype ErrorCase
  }

3. ENUM & STATE MANAGEMENT ISSUES
==================================

Issue 3.1: Incomplete Enum Usage for Status
-------------------------------------------
Location: Colors.swift (lines 281-289)
Problem:
  semantic(_ name: String) -> Color function
  
  Accepts string names like "success", "warning", etc.
  But no enum to validate these string values at compile time

Better pattern:
  enum SemanticColorRole: String, CaseIterable {
    case success, warning, info, error, neutral
  }
  
  static func semantic(_ role: SemanticColorRole) -> Color { ... }

Issue 3.2: No Visibility Group Extraction Helper
-------------------------------------------------
Location: Activity.swift
Problem:
  public enum VisibilityGroup: String, Codable, Sendable {
    case both, agent, marketing
  }

But filtering logic scattered:
  // In views/stores, no centralized place to ask:
  // "Show this activity to current user's visibility?"

Should have extension:
  extension Activity {
    func isVisibleTo(userTeam: Team) -> Bool {
      switch visibilityGroup {
      case .both: return true
      case .agent: return userTeam == .admin
      case .marketing: return userTeam == .marketing
      }
    }
  }

Issue 3.3: Task Status Enum Defined in Multiple Places
------------------------------------------------------
Location: Activity.swift (lines 34-52) & AgentTask.swift (lines 31-49)
Problem:
  TaskStatus enum duplicated in two files:
  - Activity.TaskStatus
  - AgentTask.TaskStatus

Both define same states: open, claimed, inProgress, done, failed, cancelled

This violates DRY principle. Changes must be made in both places.
Should be single shared enum in TaskCategory.swift or separate file.

4. GENERIC PROGRAMMING MISSED OPPORTUNITIES
===========================================

Issue 4.1: No Generic Sort/Filter Helpers
------------------------------------------
Location: ListingDetailStore.swift, AllListingsStore.swift
Problem:
  Repeated filtering patterns:
  
  .filter { $0.taskCategory == .marketing }
  .filter { $0.taskCategory == .admin }
  .filter { $0.taskCategory != .marketing && $0.taskCategory != .admin && ... }

Should use type-safe generic helpers:
  extension Sequence where Element: ActivityConvertible {
    func filtered(by category: TaskCategory?) -> [Element] { ... }
    func sorted(byCompletion: Bool = true) -> [Element] { ... }
  }

Issue 4.2: No Generic Repository Implementation
-----------------------------------------------
Location: TaskRepositoryClient.swift
Problem:
  TaskRepositoryClient struct (250+ lines) manually implements:
  - fetchTasks
  - fetchActivities
  - fetchDeletedTasks
  - fetchDeletedActivities
  - claimTask
  - claimActivity
  - deleteTask
  - deleteActivity
  - Plus realtor/staff variants

Much duplicated logic between tasks and activities.

Generic approach:
  struct SupabaseRepository<Entity: Identifiable & Codable & Sendable> {
    private let tableName: String
    private let supabase: SupabaseClient
    
    func fetch() async throws -> [Entity] { ... }
    func claim(_ id: String, by: String) async throws -> Entity { ... }
    func delete(_ id: String, by: String) async throws { ... }
  }

Issue 4.3: Date Formatting Not Standardized
-------------------------------------------
Location: TaskRepositoryClient.swift (lines 228, 246, 263, 275)
Problem:
  Inconsistent date formatting:
  now.ISO8601Format()  // line 228
  now.ISO8601Format()  // line 246
  now.ISO8601Format()  // line 263

Uses hardcoded format strings scattered throughout.
No centralized formatter enum.

Should use:
  enum DateFormats {
    static let iso8601 = Date.FormatStyle.iso8601
    static func encode(_ date: Date) -> String {
      date.formatted(Self.iso8601)
    }
  }

5. CODABLE IMPLEMENTATION ISSUES
================================

Issue 5.1: AnyCodable Decoding is Fallible
------------------------------------------
Location: Activity.swift (lines 234-257)
Problem:
  init(from decoder: Decoder) uses sequential try? attempts:
  
  if let int = try? container.decode(Int.self) { ... }
  else if let double = try? container.decode(Double.self) { ... }
  else if let string = try? container.decode(String.self) { ... }

This silently loses type information. A number could be decoded as Int or Double.
No guaranteed consistency if decoded multiple times.

Issue 5.2: Silent Enum Fallback in Mapping
------------------------------------------
Location: TaskRepositoryClient.swift (line 121, 123)
Problem:
  status: Activity.TaskStatus(rawValue: row.status) ?? .open
  visibilityGroup: Activity.VisibilityGroup(rawValue: row.visibilityGroup) ?? .both

Silently falls back to default values if database returns unexpected strings.
No logging, no error throwing. Silent data loss.

Better:
  func mapActivityResponse(_ row: ActivityResponse) throws -> ActivityWithDetails {
    guard let status = Activity.TaskStatus(rawValue: row.status) else {
      throw MappingError.invalidStatus(row.status)
    }
    // ...
  }

Issue 5.3: CodingKeys Duplication
---------------------------------
Location: ALL model files
Problem:
  Every model manually maps camelCase to snake_case:
  
  enum CodingKeys: String, CodingKey {
    case id = "task_id"
    case listingId = "listing_id"
    case realtorId = "realtor_id"
    // ... repeated for every model
  }

Better: Create JSONDecoder with keyDecodingStrategy:
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

6. VALUE TYPES VS REFERENCE TYPES ISSUES
=========================================

Issue 6.1: Mutable Value Types in Model
---------------------------------------
Location: Activity.swift, AgentTask.swift
Problem:
  public var status: TaskStatus  // MUTABLE
  public var assignedStaffId: String?  // MUTABLE
  public var claimedAt: Date?  // MUTABLE

Structs are value types, but marked as `var`.
This allows accidental mutation:
  activity.status = .invalid  // Compiles but violates invariants
  activity.assignedStaffId = ""  // Can set to empty string

Better:
  public let status: TaskStatus  // IMMUTABLE
  
If updates needed, require explicit update operation:
  func withUpdatedStatus(_ newStatus: TaskStatus) -> Activity {
    var copy = self
    copy.status = newStatus
    return copy
  }

Issue 6.2: Optional Flags That Should Be State
----------------------------------------------
Location: Activity.swift
Problem:
  public let deletedAt: Date?
  public let deletedBy: String?

These shouldn't be two separate fields. One should imply the other.

Better:
  public enum DeletionState: Codable, Sendable {
    case active
    case deleted(at: Date, by: String)
  }
  
  public let deletion: DeletionState

This prevents invalid states like "deletedAt = nil but deletedBy = 'user'"

7. TYPE INFERENCE AND CLARITY ISSUES
====================================

Issue 7.1: Long Conditional Chains Without Type Guards
------------------------------------------------------
Location: ListingDetailStore.swift
Problem:
  .filter { $0.taskCategory != .marketing && 
            $0.taskCategory != .admin && 
            $0.taskCategory != nil }

Hard to read. Should use explicit helper:
  func isOtherCategory(_ category: TaskCategory?) -> Bool {
    category != nil && category != .marketing && category != .admin
  }

Issue 7.2: Implicit Type Conversions
-----------------------------------
Location: AppState.swift (line 44)
Problem:
  guard let userId = currentUser?.id.uuidString else { return [] }
  return allTasks.filter { $0.assignedStaffId == userId }

Comparing UUID converted to String with String assignedStaffId.
Types match but semantics are unclear.

Better:
  typealias UserId = String
  
  struct User {
    let id: UserId  // Explicitly a user ID, not just any string
  }

8. DEPENDENCY INJECTION ISSUES
==============================

Issue 8.1: Repository Client Uses Bare Strings for Validation
-----------------------------------------------------------
Location: TaskRepositoryClient.swift (line 313-314)
Problem:
  .eq("status", value: AgentTask.TaskStatus.done.rawValue)
  .filter("deleted_at", operator: "not.is.null", value: "")

String-based filter operators. No type safety for Supabase query building.

Better:
  enum FilterOperator: String {
    case notIsNull = "not.is.null"
    case equals = "eq"
    // ...
  }

Issue 8.2: No Dependency Version Validation
-------------------------------------------
Location: All stores
Problem:
  No way to verify TaskRepositoryClient is .live or .preview at runtime.
  Could accidentally use preview in production or vice versa.

Solution:
  enum RepositoryMode {
    case production
    case preview
    case testing
  }
  
  Store can verify: guard mode != .preview else { ... }

9. ID TYPED AS STRING EVERYWHERE
================================

Issue 9.1: String IDs Lack Type Safety
--------------------------------------
Location: ALL models and stores
Problem:
  Task ID: String
  Listing ID: String
  Realtor ID: String
  Staff ID: String
  User ID: String
  
Can accidentally mix types:
  task.assignedStaffId = listing.id  // COMPILES but logically wrong

Better approach:
  typealias TaskId = String
  typealias ListingId = String
  typealias UserId = String
  
  struct Activity {
    let id: TaskId
    let listingId: ListingId
    let assignedStaffId: UserId?
  }

Compiler prevents mixing ID types.

10. RESPONSE MODELS VS DOMAIN MODELS
====================================

Issue 10.1: Internal Response Models Lack Isolation
-------------------------------------------------
Location: TaskRepositoryClient.swift (lines 57-102)
Problem:
  ActivityResponse struct has same structure as Activity model.
  Changes to database representation leak into domain layer.

Better:
  Keep ActivityResponse private (already done).
  But ActivityResponse should have different fields than Activity:
  - No computed properties
  - All fields optional for partial updates
  - Different JSON mapping requirements

Issue 10.2: No Validation Layer
-------------------------------
Problem:
  Models decoded directly from JSON without validation.
  Example: Activity with priority = -100? Never validated.
  
Add validation:
  struct Activity {
    private let _priority: Int
    
    var priority: Int {
      get { _priority }
      set { _priority = max(0, min(100, newValue)) }
    }
  }

SUMMARY OF VIOLATIONS BY SEVERITY
==================================

CRITICAL (Type System Not Preventing Bugs):
  1. String-based type fields (ListingNote.type, Listing.status/type)
  2. AnyCodable usage (16 instances) - loses type info
  3. Silent enum fallbacks with ?? defaults
  4. No validation of decoded values
  5. String ID mixing (TaskId vs ListingId)

HIGH (Design Flaws):
  1. Duplicated TaskStatus enum (Activity vs AgentTask)
  2. Metadata fields with Any type
  3. Optional flags that should be state enums
  4. Missing Auditable protocol
  5. Generic repository code duplication

MEDIUM (Code Quality):
  1. CodingKeys duplication across models
  2. Scattered filtering/sorting logic
  3. Unclear type conversions (UUID -> String)
  4. Long conditional chains
  5. No centralized date formatting

TYPE SAFETY SCORE: 4.5/10
=========================

What's Working Well:
  - Enums for TaskCategory, TaskStatus, AuthError
  - Sendable conformance throughout
  - Codable with explicit CodingKeys
  - @Observable and @MainActor isolation

What Needs Work:
  - Eliminate String-based type fields
  - Replace AnyCodable with typed structures
  - Add validation layer for decoded values
  - Create ID type aliases
  - Implement Auditable protocol
  - Consolidate duplicate enums
