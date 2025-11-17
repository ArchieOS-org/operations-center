# Swift Frontend Variable Naming Conventions - Backend Integration Guide

## Overview
The backend MUST use these exact variable names when interacting with the Swift frontend. The frontend expects specific JSON keys that decode through CodingKeys defined in Swift models.

---

## 1. ACTIVITY MODEL (Listing-Specific Tasks)

### Database Table: `activities`

### Swift Model Properties (What Backend Receives)
```swift
public struct Activity: Identifiable, Codable, Sendable {
    public let id: String                          // From: task_id
    public let listingId: String                   // From: listing_id
    public let realtorId: String?                  // From: realtor_id
    public let name: String
    public let description: String?
    public let taskCategory: TaskCategory?         // From: task_category
    public var status: TaskStatus
    public let priority: Int
    public let visibilityGroup: VisibilityGroup   // From: visibility_group
    public var assignedStaffId: String?            // From: assigned_staff_id
    public let dueDate: Date?                      // From: due_date
    public var claimedAt: Date?                    // From: claimed_at
    public let completedAt: Date?                  // From: completed_at
    public let createdAt: Date                     // From: created_at
    public let updatedAt: Date                     // From: updated_at
    public let deletedAt: Date?                    // From: deleted_at
    public let deletedBy: String?                  // From: deleted_by
    public let inputs: [String: AnyCodable]?
    public let outputs: [String: AnyCodable]?
}
```

### CodingKeys (Database Column Names)
```
task_id → Activity.id
listing_id → Activity.listingId
realtor_id → Activity.realtorId
name → Activity.name
description → Activity.description
task_category → Activity.taskCategory
status → Activity.status
priority → Activity.priority
visibility_group → Activity.visibilityGroup
assigned_staff_id → Activity.assignedStaffId
due_date → Activity.dueDate
claimed_at → Activity.claimedAt
completed_at → Activity.completedAt
created_at → Activity.createdAt
updated_at → Activity.updatedAt
deleted_at → Activity.deletedAt
deleted_by → Activity.deletedBy
inputs → Activity.inputs
outputs → Activity.outputs
```

### Enums
```swift
enum TaskStatus: String {
    case open = "OPEN"
    case claimed = "CLAIMED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}

enum VisibilityGroup: String {
    case both = "BOTH"
    case agent = "AGENT"
    case marketing = "MARKETING"
}
```

### Sample JSON for Backend → Frontend
```json
{
    "task_id": "activity_001",
    "listing_id": "listing_001",
    "realtor_id": "realtor_001",
    "name": "Professional Photography",
    "description": "Schedule and complete professional photography",
    "task_category": "MARKETING",
    "status": "OPEN",
    "priority": 100,
    "visibility_group": "BOTH",
    "assigned_staff_id": null,
    "due_date": "2025-11-18T12:00:00Z",
    "claimed_at": null,
    "completed_at": null,
    "created_at": "2025-11-11T12:00:00Z",
    "updated_at": "2025-11-11T12:00:00Z",
    "deleted_at": null,
    "deleted_by": null,
    "inputs": {"photographer": "John Smith Photography"},
    "outputs": null
}
```

---

## 2. AGENT TASK MODEL (Realtor-Specific Tasks)

### Database Table: `agent_tasks`

### Swift Model Properties (What Backend Receives)
```swift
public struct AgentTask: Identifiable, Codable, Sendable {
    public let id: String                          // From: task_id
    public let realtorId: String                   // From: realtor_id
    public let name: String
    public let description: String?
    public let taskCategory: TaskCategory?         // From: task_category
    public var listingId: String?                  // From: listing_id
    public var status: TaskStatus
    public let priority: Int
    public var assignedStaffId: String?            // From: assigned_staff_id
    public let dueDate: Date?                      // From: due_date
    public var claimedAt: Date?                    // From: claimed_at
    public let completedAt: Date?                  // From: completed_at
    public let createdAt: Date                     // From: created_at
    public let updatedAt: Date                     // From: updated_at
    public let deletedAt: Date?                    // From: deleted_at
    public let deletedBy: String?                  // From: deleted_by
}
```

### CodingKeys (Database Column Names)
```
task_id → AgentTask.id
realtor_id → AgentTask.realtorId
name → AgentTask.name
description → AgentTask.description
task_category → AgentTask.taskCategory
listing_id → AgentTask.listingId
status → AgentTask.status
priority → AgentTask.priority
assigned_staff_id → AgentTask.assignedStaffId
due_date → AgentTask.dueDate
claimed_at → AgentTask.claimedAt
completed_at → AgentTask.completedAt
created_at → AgentTask.createdAt
updated_at → AgentTask.updatedAt
deleted_at → AgentTask.deletedAt
deleted_by → AgentTask.deletedBy
```

### Enums (Same as Activity)
```swift
enum TaskStatus: String {
    case open = "OPEN"
    case claimed = "CLAIMED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}
```

### Sample JSON for Backend → Frontend
```json
{
    "task_id": "task_001",
    "realtor_id": "realtor_001",
    "name": "Update CRM Records",
    "description": "Update all client contact information",
    "task_category": "ADMIN",
    "listing_id": null,
    "status": "OPEN",
    "priority": 75,
    "assigned_staff_id": null,
    "due_date": "2025-11-17T12:00:00Z",
    "claimed_at": null,
    "completed_at": null,
    "created_at": "2025-11-11T12:00:00Z",
    "updated_at": "2025-11-11T12:00:00Z",
    "deleted_at": null,
    "deleted_by": null
}
```

---

## 3. LISTING MODEL

### Database Table: `listings`

### Swift Model Properties
```swift
public struct Listing: Identifiable, Codable, Sendable {
    public let id: String                          // From: listing_id
    public let addressString: String               // From: address_string
    public let status: String
    public let assignee: String?
    public let realtorId: String?                  // From: realtor_id
    public let dueDate: Date?                      // From: due_date
    public let progress: Decimal?
    public let type: String?
    public let notes: String
    public let createdAt: Date                     // From: created_at
    public let updatedAt: Date                     // From: updated_at
    public let completedAt: Date?                  // From: completed_at
    public let deletedAt: Date?                    // From: deleted_at
}
```

### CodingKeys (Database Column Names)
```
listing_id → Listing.id
address_string → Listing.addressString
status → Listing.status
assignee → Listing.assignee
realtor_id → Listing.realtorId
due_date → Listing.dueDate
progress → Listing.progress
type → Listing.type
notes → Listing.notes
created_at → Listing.createdAt
updated_at → Listing.updatedAt
completed_at → Listing.completedAt
deleted_at → Listing.deletedAt
```

### Sample JSON
```json
{
    "listing_id": "listing_001",
    "address_string": "123 Main St, San Francisco, CA 94102",
    "status": "ACTIVE",
    "assignee": "staff_001",
    "realtor_id": "realtor_001",
    "due_date": "2025-11-25T12:00:00Z",
    "progress": 0.45,
    "type": "SALE",
    "notes": "Prime location, needs staging",
    "created_at": "2025-10-26T12:00:00Z",
    "updated_at": "2025-11-15T12:00:00Z",
    "completed_at": null,
    "deleted_at": null
}
```

---

## 4. TASK CATEGORY ENUM

### Swift Definition
```swift
public enum TaskCategory: String, Codable, Sendable {
    case admin = "ADMIN"
    case marketing = "MARKETING"
    case photo = "PHOTO"
    case staging = "STAGING"
    case inspection = "INSPECTION"
    case other = "OTHER"
}
```

### Valid Database Values
```
ADMIN
MARKETING
PHOTO
STAGING
INSPECTION
OTHER
```

---

## 5. LISTING ACKNOWLEDGMENT MODEL

### Database Table: `listing_acknowledgments`

### Swift Model Properties
```swift
public struct ListingAcknowledgment: Identifiable, Codable, Sendable {
    public let id: String
    public let listingId: String                   // From: listing_id
    public let staffId: String                     // From: staff_id
    public let acknowledgedAt: Date                // From: acknowledged_at
    public let acknowledgedFrom: AcknowledgmentSource?  // From: acknowledged_from
}
```

### CodingKeys (Database Column Names)
```
id → ListingAcknowledgment.id
listing_id → ListingAcknowledgment.listingId
staff_id → ListingAcknowledgment.staffId
acknowledged_at → ListingAcknowledgment.acknowledgedAt
acknowledged_from → ListingAcknowledgment.acknowledgedFrom
```

### Enums
```swift
public enum AcknowledgmentSource: String, Codable, Sendable {
    case mobile = "mobile"
    case web = "web"
    case notification = "notification"
}
```

### Sample JSON
```json
{
    "id": "ack_001",
    "listing_id": "listing_001",
    "staff_id": "staff_001",
    "acknowledged_at": "2025-11-15T10:30:00Z",
    "acknowledged_from": "mobile"
}
```

---

## 6. COMPOSITE MODELS

### ActivityWithDetails (For Frontend Display)
The frontend bundles Activity + Listing together for UI rendering:
```swift
public struct ActivityWithDetails: Sendable {
    public let task: Activity
    public let listing: Listing
}
```

### TaskWithMessages (For Frontend Display)
The frontend bundles AgentTask + SlackMessages together:
```swift
public struct TaskWithMessages: Sendable {
    public let task: AgentTask
    public let messages: [SlackMessage]
}
```

---

## 7. DATE HANDLING

**CRITICAL**: Backend MUST send ISO 8601 formatted dates:
```
Format: YYYY-MM-DDTHH:MM:SSZ or YYYY-MM-DDTHH:MM:SS+00:00
Example: 2025-11-16T14:30:45Z
```

Swift's `Date` type will automatically decode from ISO 8601. The frontend uses:
```swift
Date().ISO8601Format()  // For encoding
```

---

## 8. DECIMAL/NUMERIC HANDLING

The `progress` field in Listing uses Swift's `Decimal` type for precision:
```
Database: NUMERIC(5,2)
Swift: Decimal
Range: 0.00 to 100.00
Example: 0.45 or "0.45" (both work)
```

---

## 9. REQUIRED VS OPTIONAL FIELDS

### Activity/AgentTask Required Fields
- `id` (task_id)
- `name`
- `status`
- `priority`
- `createdAt`
- `updatedAt`

### Activity-Specific Required Fields
- `listingId`
- `visibilityGroup`

### AgentTask-Specific Required Fields
- `realtorId`

### All Other Fields Are Optional
- Can be `null` in JSON
- Marked as `String?`, `Date?`, etc. in Swift

---

## 10. BACKEND IMPLEMENTATION CHECKLIST

When writing backend code to return Activity/AgentTask/Listing data:

- [ ] Use exact database column names (snake_case): `task_id`, `listing_id`, `realtor_id`, etc.
- [ ] Format all dates as ISO 8601: `2025-11-16T14:30:45Z`
- [ ] Use UPPERCASE enums: `"OPEN"`, `"CLAIMED"`, `"IN_PROGRESS"`, `"DONE"`, `"FAILED"`, `"CANCELLED"`
- [ ] For TaskCategory use: `"ADMIN"`, `"MARKETING"`, `"PHOTO"`, `"STAGING"`, `"INSPECTION"`, `"OTHER"`
- [ ] For VisibilityGroup use: `"BOTH"`, `"AGENT"`, `"MARKETING"` (Activities only)
- [ ] For AcknowledgmentSource use: `"mobile"`, `"web"`, `"notification"` (lowercase for this enum)
- [ ] Send `null` for optional fields (don't omit them)
- [ ] Decimal values can be numeric: `0.45` or string: `"0.45"`
- [ ] IDs are always strings, never integers
- [ ] Priority is an integer (0-10+ range)

---

## 11. COMMON PITFALLS TO AVOID

1. **❌ Wrong Enum Case**: `"open"` instead of `"OPEN"` → Decoding fails silently
2. **❌ Wrong Date Format**: Unix timestamp instead of ISO 8601 → Date parsing fails
3. **❌ Omitted Optional Fields**: Backend sends `{}` instead of `{...,"field":null}` → Can cause issues
4. **❌ Snake_case in Swift code**: Write `listingId` not `listing_id` in Swift
5. **❌ Integer IDs**: Send `1` instead of `"1"` → Type mismatch error
6. **❌ CamelCase in Database**: Column name `listingId` instead of `listing_id` → Mapping breaks
7. **❌ Missing visibility_group in Activities**: Required field for Activities, will default to "BOTH" if omitted
8. **❌ Wrong table name**: Using `listing_tasks` instead of `activities` after migration 016

---

## 12. QUICK REFERENCE TABLE

| Entity | Database Table | Swift Model | Primary Key | ID Column |
|--------|---------------|-------------|-------------|-----------|
| Activity | `activities` | `Activity` | task_id | `id` |
| Agent Task | `agent_tasks` | `AgentTask` | task_id | `id` |
| Listing | `listings` | `Listing` | listing_id | `id` |
| Acknowledgment | `listing_acknowledgments` | `ListingAcknowledgment` | id | `id` |

---

## Summary

The backend's job is to:
1. Query Supabase tables directly (activities, agent_tasks, listings, listing_acknowledgments)
2. Return JSON with **snake_case** column names exactly as defined in CodingKeys
3. Format dates as ISO 8601
4. Use UPPERCASE for status/category enums
5. Always include optional fields (can be null)
6. The frontend will automatically decode using CodingKeys and convert to camelCase Swift properties

**The frontend takes care of the rest** - encoding/decoding, type conversion, UI rendering.
