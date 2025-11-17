# Operations Center Database Schema Reference

## Table 1: activities (Listing-Specific Tasks)

**Created by**: Migration 012 (originally `listing_tasks`), renamed in migration 016

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `task_id` | TEXT | PRIMARY KEY | Unique task identifier |
| `listing_id` | TEXT | NOT NULL, FK → listings | Links to listing |
| `realtor_id` | TEXT | FK → realtors, ON DELETE SET NULL | Can be null |
| `name` | TEXT | NOT NULL | Task title |
| `description` | TEXT | NULL | Long-form description |
| `task_category` | TEXT | CHECK IN ('ADMIN', 'MARKETING', 'PHOTO', 'STAGING', 'INSPECTION', 'OTHER') | Activity category |
| `status` | TEXT | NOT NULL, DEFAULT 'OPEN' | One of: OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED |
| `priority` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 AND <= 10 | Range 0-10 |
| `visibility_group` | TEXT | NOT NULL, DEFAULT 'BOTH' | One of: BOTH, AGENT, MARKETING |
| `assigned_staff_id` | TEXT | FK → staff, ON DELETE SET NULL | Currently assigned person |
| `due_date` | TIMESTAMPTZ | NULL | Task due date |
| `claimed_at` | TIMESTAMPTZ | NULL | When task was claimed |
| `completed_at` | TIMESTAMPTZ | NULL | When task was completed |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp (auto-updated by trigger) |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |
| `deleted_by` | TEXT | NULL | User who deleted |
| `inputs` | JSONB | DEFAULT '{}' | Task input parameters |
| `outputs` | JSONB | DEFAULT '{}' | Task output results |

**Indexes**:
- `idx_activities_listing` on (listing_id)
- `idx_activities_realtor` on (realtor_id)
- `idx_activities_assigned_staff` on (assigned_staff_id)
- `idx_activities_status` on (status)
- `idx_activities_category` on (task_category)
- `idx_activities_due_date` on (due_date)

**Trigger**: `trigger_update_activities_updated_at` updates `updated_at` on every UPDATE

---

## Table 2: agent_tasks (Realtor-Specific Tasks)

**Created by**: Migration 012 (originally `stray_tasks`), renamed in migration 016

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `task_id` | TEXT | PRIMARY KEY | Unique task identifier |
| `realtor_id` | TEXT | NOT NULL, FK → realtors | Links to realtor |
| `name` | TEXT | NOT NULL | Task title |
| `description` | TEXT | NULL | Long-form description |
| `task_category` | TEXT | CHECK IN ('ADMIN', 'MARKETING', 'PHOTO', 'STAGING', 'INSPECTION', 'OTHER') | Task category (optional in model) |
| `listing_id` | TEXT | FK → listings, NULL | Optional listing assignment (migration 019) |
| `status` | TEXT | NOT NULL, DEFAULT 'OPEN' | One of: OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED |
| `priority` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 AND <= 10 | Range 0-10 |
| `assigned_staff_id` | TEXT | FK → staff, ON DELETE SET NULL | Currently assigned person |
| `due_date` | TIMESTAMPTZ | NULL | Task due date |
| `claimed_at` | TIMESTAMPTZ | NULL | When task was claimed |
| `completed_at` | TIMESTAMPTZ | NULL | When task was completed |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp (auto-updated by trigger) |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |
| `deleted_by` | TEXT | NULL | User who deleted |

**Indexes**:
- `idx_agent_tasks_realtor` on (realtor_id)
- `idx_agent_tasks_assigned_staff` on (assigned_staff_id)
- `idx_agent_tasks_status` on (status)
- `idx_agent_tasks_task_key` on (task_key) if exists
- `idx_agent_tasks_due_date` on (due_date)

**Trigger**: `trigger_update_agent_tasks_updated_at` updates `updated_at` on every UPDATE

**Unique Constraint** (from original stray_tasks):
- UNIQUE(realtor_id, task_key) if task_key column exists

---

## Table 3: listings (Real Estate Listings)

**Created by**: Migration 003

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `listing_id` | TEXT | PRIMARY KEY | Unique listing identifier |
| `address_string` | TEXT | NOT NULL | Full property address |
| `status` | TEXT | NOT NULL | Listing status (free-form string) |
| `assignee` | TEXT | NULL | Currently assigned staff member |
| `realtor_id` | TEXT | FK → realtors, ON DELETE SET NULL | Associated realtor (migration 014) |
| `due_date` | TIMESTAMPTZ | NULL | Listing deadline |
| `progress` | NUMERIC(5,2) | CHECK >= 0 AND <= 100 | Progress percentage (0.00-100.00) |
| `type` | TEXT | NULL | Listing type (SALE, RENTAL, COMMERCIAL, RESIDENTIAL) |
| `notes` | TEXT | NOT NULL | General notes about listing |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp (auto-updated by trigger) |
| `completed_at` | TIMESTAMPTZ | NULL | When listing was completed |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |

**Indexes**:
- `idx_listings_status` on (status) WHERE deleted_at IS NULL
- `idx_listings_assignee` on (assignee) WHERE deleted_at IS NULL
- `idx_listings_agent` on (agent_id) WHERE deleted_at IS NULL
- `idx_listings_created` on (created_at) WHERE deleted_at IS NULL
- `idx_listings_due_date` on (due_date) WHERE deleted_at IS NULL
- `idx_listings_address` on (address_string) WHERE deleted_at IS NULL

**Trigger**: `listings_updated_at` updates `updated_at` on every UPDATE

---

## Table 4: listing_acknowledgments (Per-User Acknowledgment)

**Created by**: Migration 020

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | TEXT | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique acknowledgment record |
| `listing_id` | TEXT | NOT NULL, FK → listings | Links to listing |
| `staff_id` | TEXT | NOT NULL, FK → staff | Links to staff member |
| `acknowledged_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | When acknowledged |
| `acknowledged_from` | TEXT | CHECK IN ('mobile', 'web', 'notification') | Source platform |

**Unique Constraint**:
- UNIQUE(listing_id, staff_id) - One acknowledgment per staff per listing

**Indexes**:
- `idx_listing_acks_staff` on (staff_id)
- `idx_listing_acks_listing` on (listing_id)
- `idx_listing_acks_timestamp` on (acknowledged_at)

---

## Supporting Tables (Referenced by above)

### Table: realtors
| Column | Type | Key |
|--------|------|-----|
| `realtor_id` | TEXT | PRIMARY KEY |
| ... | ... | ... |

### Table: staff
| Column | Type | Key |
|--------|------|-----|
| `staff_id` | TEXT | PRIMARY KEY |
| ... | ... | ... |

---

## Important Migration History

1. **Migration 003**: Initial `listings`, `listing_details`, `listing_notes`, `audit_log` tables
2. **Migration 012**: Creates `listing_tasks` and `stray_tasks` tables
3. **Migration 014**: Adds `realtor_id` to listings
4. **Migration 016**: **CRITICAL RENAMES**
   - `stray_tasks` → `agent_tasks`
   - `listing_tasks` → `activities`
   - All triggers and indexes renamed accordingly
5. **Migration 017**: Adds missing columns to agent_tasks
6. **Migration 018**: Simplifies task categories
7. **Migration 019**: Adds `listing_id` to `agent_tasks` (optional linking)
8. **Migration 020**: Creates `listing_acknowledgments` junction table

**CRITICAL**: After migration 016, the table names are:
- `activities` (NOT `listing_tasks`)
- `agent_tasks` (NOT `stray_tasks`)

---

## Type Mappings

| Swift Type | Database Type | JSON Format |
|-----------|--------------|------------|
| `String` | TEXT | `"value"` |
| `String?` | TEXT | `"value"` or `null` |
| `Date` | TIMESTAMPTZ | `"2025-11-16T14:30:45Z"` |
| `Date?` | TIMESTAMPTZ | `"2025-11-16T14:30:45Z"` or `null` |
| `Int` | INTEGER | `42` |
| `Decimal` | NUMERIC(5,2) | `0.45` or `"0.45"` |
| `[String: Any]` | JSONB | `{"key": "value"}` |

---

## Query Examples (for backend developers)

### Fetch All Non-Deleted Activities
```sql
SELECT * FROM activities
WHERE deleted_at IS NULL
ORDER BY priority DESC, created_at DESC;
```

### Fetch Activities for a Listing
```sql
SELECT * FROM activities
WHERE listing_id = $1
  AND deleted_at IS NULL
ORDER BY priority DESC;
```

### Fetch Agent Tasks for a Realtor
```sql
SELECT * FROM agent_tasks
WHERE realtor_id = $1
  AND deleted_at IS NULL
ORDER BY priority DESC;
```

### Fetch Unacknowledged Listings for a Staff Member
```sql
SELECT l.* FROM listings l
WHERE l.deleted_at IS NULL
  AND l.completed_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM listing_acknowledgments la
    WHERE la.listing_id = l.listing_id
    AND la.staff_id = $1
  )
ORDER BY l.created_at DESC;
```

### Claim an Activity (Update Status & Dates)
```sql
UPDATE activities
SET 
  assigned_staff_id = $1,
  claimed_at = NOW(),
  status = 'CLAIMED',
  updated_at = NOW()
WHERE task_id = $2
RETURNING *;
```

### Soft Delete an Activity
```sql
UPDATE activities
SET 
  deleted_at = NOW(),
  deleted_by = $1,
  updated_at = NOW()
WHERE task_id = $2;
```

---

## RLS (Row Level Security) Status

All tables have RLS **enabled** but no policies defined yet:
- `listings`
- `listing_details`
- `listing_notes`
- `audit_log`
- `listing_acknowledgments`
- `activities`
- `agent_tasks`

**Current Behavior**: With RLS enabled but no policies, the Supabase client can still access data using the authenticated session. Add explicit policies if needed for security.

