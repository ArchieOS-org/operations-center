# Sync Models

Update Swift models to match the Supabase database schema.

## Instructions

When this command is used:

1. **Check Supabase schema**
   - Review database tables structure
   - Identify new columns or tables
   - Note type changes

2. **Update Swift models**
   - Add/remove properties to match schema
   - Ensure proper Codable conformance
   - Use correct Swift types for PostgreSQL types

3. **Verify JSON key mapping**
   - Match database column names (snake_case)
   - Use CodingKeys if needed
   - Handle optional vs required fields

4. **Update everywhere**
   - Models in `Packages/Models/Sources/Models/`
   - Update related ViewModels
   - Fix any broken tests

## PostgreSQL to Swift Type Mapping

| PostgreSQL Type | Swift Type |
|----------------|------------|
| `uuid` | `String` or `UUID` |
| `text` | `String` |
| `integer` | `Int` |
| `bigint` | `Int64` |
| `boolean` | `Bool` |
| `timestamp with time zone` | `Date` |
| `jsonb` | `[String: Any]` or custom Codable |
| `text[]` | `[String]` |

## Example

**Supabase Table: `listing_tasks`**
```sql
CREATE TABLE listing_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    status text NOT NULL,
    assigned_to uuid REFERENCES staff(id),
    listing_id uuid REFERENCES listings(id),
    due_date timestamp with time zone,
    is_deleted boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    metadata jsonb DEFAULT '{}'::jsonb
);
```

**Swift Model:**
```swift
// Packages/Models/Sources/Models/ListingTask.swift
import Foundation

public struct ListingTask: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String?
    public var status: TaskStatus
    public var assignedTo: String?
    public var listingId: String?
    public var dueDate: Date?
    public var isDeleted: Bool
    public let createdAt: Date
    public var updatedAt: Date
    public var metadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case status
        case assignedTo = "assigned_to"
        case listingId = "listing_id"
        case dueDate = "due_date"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case metadata
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        status: TaskStatus,
        assignedTo: String? = nil,
        listingId: String? = nil,
        dueDate: Date? = nil,
        isDeleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.assignedTo = assignedTo
        self.listingId = listingId
        self.dueDate = dueDate
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}

public enum TaskStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
    case cancelled
}
```

## Checklist

When syncing models:

- [ ] All database columns represented in Swift
- [ ] CodingKeys map snake_case to camelCase
- [ ] Proper optionality (nullable → optional)
- [ ] Date fields use proper ISO8601 strategy
- [ ] Enums for constrained text fields
- [ ] Public initializer with defaults
- [ ] Identifiable conformance (for lists)
- [ ] Equatable conformance (for comparisons)
- [ ] Models file in Packages/Models/
- [ ] Related services updated
- [ ] Tests pass

## Related Tables to Sync

Current database tables:
- `staff`
- `realtors`
- `listing_tasks`
- `stray_tasks`
- `listings`
- `slack_messages`
- `task_notes`

Run this command whenever:
- Database migrations are applied
- New tables are added
- Column types change
- You see Codable errors
