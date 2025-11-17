# Supabase Database Schema - Complete Picture

## Executive Summary

The Operations Center database contains **9 core tables** organized into three domains:

1. **People Management** (staff, realtors)
2. **Property & Activity Management** (listings, activities, agent_tasks, listing_acknowledgments)
3. **Infrastructure** (slack_messages, listing_notes, task_notes)

All tables use ULID/UUID for IDs, JSONB for flexible data, and soft deletes via `deleted_at` timestamps.

---

## Core Tables (9 Total)

### 1. STAFF TABLE
**Purpose:** Internal team members (operations, marketing, admin)
**Status:** Active and established

| Column | Type | Key Properties |
|--------|------|-----------------|
| staff_id | TEXT PRIMARY KEY | ULID format |
| email | TEXT UNIQUE NOT NULL | Unique identifier |
| name | TEXT NOT NULL | Display name |
| role | TEXT CHECK() | admin, operations, marketing, support |
| slack_user_id | TEXT UNIQUE | Slack integration |
| phone | TEXT | Contact info |
| status | TEXT CHECK() | active, inactive, suspended |
| created_at / updated_at | TIMESTAMPTZ | Auto-managed |
| deleted_at | TIMESTAMPTZ | Soft delete |
| metadata | JSONB | Flexible storage |

**Indexes:**
- role (non-deleted)
- status (non-deleted)
- slack_user_id (non-deleted)
- email (non-deleted)

**Triggers:** AUTO-UPDATE updated_at on every write

---

### 2. REALTORS TABLE
**Purpose:** External real estate agents and brokers
**Status:** Active and established

| Column | Type | Key Properties |
|--------|------|-----------------|
| realtor_id | TEXT PRIMARY KEY | ULID format |
| email | TEXT UNIQUE NOT NULL | Unique identifier |
| name | TEXT NOT NULL | Display name |
| license_number | TEXT UNIQUE | Real estate license |
| brokerage | TEXT | Firm name |
| slack_user_id | TEXT UNIQUE | Slack integration |
| phone | TEXT | Contact info |
| territories | TEXT[] | Geographic regions (ARRAY) |
| status | TEXT CHECK() | active, inactive, suspended, pending |
| created_at / updated_at | TIMESTAMPTZ | Auto-managed |
| deleted_at | TIMESTAMPTZ | Soft delete |
| metadata | JSONB | Flexible storage |

**Indexes:**
- status (non-deleted)
- slack_user_id (non-deleted)
- email (non-deleted)
- license_number (non-deleted)
- brokerage (non-deleted)
- territories (GIN - array search)

**Triggers:** AUTO-UPDATE updated_at on every write

---

### 3. LISTINGS TABLE
**Purpose:** Real estate properties being managed
**Status:** Mature with supporting detail tables

| Column | Type | Key Properties |
|--------|------|-----------------|
| listing_id | TEXT PRIMARY KEY | ULID format |
| address_string | TEXT NOT NULL | Property address |
| status | TEXT CHECK() | new, in_progress, completed |
| assignee | TEXT | Person responsible |
| agent_id / realtor_id | TEXT | Associated realtor |
| due_date | TIMESTAMPTZ | Target completion |
| progress | NUMERIC(5,2) | 0-100% |
| type | TEXT | Property type |
| created_at / updated_at | TIMESTAMPTZ | Auto-managed |
| deleted_at | TIMESTAMPTZ | Soft delete |

**Indexes:**
- status (non-deleted)
- assignee (non-deleted)
- agent_id (non-deleted)
- created_at (non-deleted)
- due_date (non-deleted)
- address_string (non-deleted)

**Triggers:** AUTO-UPDATE updated_at on every write

**Supporting Tables:**
- `listing_details(id, listing_id, property_type, bedrooms, bathrooms, sqft, year_built, list_price, notes)`
- `listing_notes(note_id, listing_id, content, type, created_by)`

---

### 4. LISTING_ACKNOWLEDGMENTS TABLE
**Purpose:** Per-user acknowledgment tracking for listings (CRITICAL for Inbox → MyListings workflow)
**Status:** Recently added (migration 020) - FOUNDATIONAL FOR FEATURE COMPLETENESS

| Column | Type | Key Properties |
|--------|------|-----------------|
| id | TEXT PRIMARY KEY | UUID format |
| listing_id | TEXT FK | References listings(listing_id) CASCADE |
| staff_id | TEXT FK | References staff(staff_id) CASCADE |
| acknowledged_at | TIMESTAMPTZ | When acknowledged |
| acknowledged_from | TEXT CHECK() | mobile, web, notification |

**Constraints:**
- UNIQUE(listing_id, staff_id) - One ack per user per listing

**Indexes:**
- staff_id
- listing_id
- acknowledged_at

**Purpose in Product:**
- When staff "acknowledges" a listing in Inbox, insert row here
- MyListings view queries: `SELECT DISTINCT listings WHERE listing_acknowledgments.staff_id = current_user`
- This implements the "Claimed vs Unclaimed" state model

---

### 5. ACTIVITIES TABLE (formerly listing_tasks)
**Purpose:** Listing-specific coordinated workflows (photo, staging, inspection, marketing)
**Status:** Active and renamed in migration 016

| Column | Type | Key Properties |
|--------|------|-----------------|
| task_id | TEXT PRIMARY KEY | ULID format |
| listing_id | TEXT FK NOT NULL | References listings(listing_id) CASCADE |
| realtor_id | TEXT FK | Associated realtor |
| name | TEXT NOT NULL | Activity name |
| description | TEXT | Details |
| task_category | TEXT CHECK() | ADMIN, MARKETING, or NULL |
| status | TEXT CHECK() | OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED |
| priority | INTEGER | 0-10 scale |
| visibility_group | TEXT CHECK() | BOTH, AGENT, MARKETING |
| assigned_staff_id | TEXT FK | Staff member handling it |
| due_date / claimed_at / completed_at | TIMESTAMPTZ | Timeline tracking |
| created_at / updated_at / deleted_at | TIMESTAMPTZ | Audit trail |
| inputs / outputs | JSONB | Task data |

**Indexes:**
- listing_id (non-deleted)
- realtor_id (non-deleted)
- assigned_staff_id + due_date (non-deleted)
- status + priority DESC (non-deleted)
- task_category (non-deleted)
- listing_id + status + priority (non-deleted)

**Triggers:** AUTO-UPDATE updated_at on every write

**Role in Product:**
- Shows in Inbox (unclaimed)
- Shows in MyListings (grouped by listing) when staff claims them
- Supports "All activities done → listing moves to Logbook" workflow

---

### 6. AGENT_TASKS TABLE (formerly stray_tasks)
**Purpose:** Realtor-specific tasks not tied to a listing (general support, admin work)
**Status:** Active and renamed in migration 016

| Column | Type | Key Properties |
|--------|------|-----------------|
| task_id | TEXT PRIMARY KEY | ULID format |
| realtor_id | TEXT FK NOT NULL | References realtors(realtor_id) CASCADE |
| task_key | TEXT NOT NULL | Classification key from LangChain |
| name | TEXT NOT NULL | Task name |
| description | TEXT | Details |
| status | TEXT CHECK() | OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED |
| priority | INTEGER | 0-10 scale |
| assigned_staff_id | TEXT FK | Staff member helping realtor |
| due_date / claimed_at / completed_at | TIMESTAMPTZ | Timeline tracking |
| created_at / updated_at / deleted_at | TIMESTAMPTZ | Audit trail |
| inputs / outputs | JSONB | Task data |
| notes | TEXT | Additional context |

**Constraints:**
- UNIQUE(realtor_id, task_key) - One of each task type per realtor

**Indexes:**
- realtor_id + created_at DESC (non-deleted)
- assigned_staff_id + due_date (non-deleted)
- status + priority DESC (non-deleted)
- task_key (non-deleted)

**Triggers:** AUTO-UPDATE updated_at on every write

**Role in Product:**
- Created by AI classifier from Slack messages
- Shows in Inbox (unclaimed)
- Assigned to staff for execution

---

### 7. SLACK_MESSAGES TABLE
**Purpose:** Audit trail + classification results from Slack intake workflow
**Status:** Active - bridge between Slack and database state

| Column | Type | Key Properties |
|--------|------|-----------------|
| message_id | TEXT PRIMARY KEY | ULID format |
| slack_user_id | TEXT NOT NULL | Who sent it |
| slack_channel_id | TEXT NOT NULL | Which channel |
| slack_ts | TEXT NOT NULL UNIQUE | Slack message timestamp |
| slack_thread_ts | TEXT | Thread context |
| message_text | TEXT NOT NULL | Raw message |
| classification | JSONB NOT NULL | Full result from LangChain classifier |
| message_type | TEXT NOT NULL | new_listing, task_request, etc. |
| task_key / group_key | TEXT | Classification taxonomy |
| confidence | NUMERIC(5,4) | 0.0-1.0 classification confidence |
| created_listing_id | TEXT FK | Listing created from this message |
| created_task_id | TEXT | Task ID created |
| created_task_type | TEXT CHECK() | listing_task, stray_task |
| received_at / processed_at | TIMESTAMPTZ | Timeline |
| processing_status | TEXT CHECK() | pending, processed, failed, skipped |
| error_message | TEXT | If processing failed |
| metadata | JSONB | Additional context |

**Indexes:**
- slack_user_id + received_at DESC
- slack_channel_id + received_at DESC
- slack_ts
- slack_thread_ts (where not null)
- message_type
- task_key (where not null)
- processing_status + received_at DESC
- created_listing_id (where not null)
- created_task_id + created_task_type (where not null)

**Purpose in Product:**
- One-way flow: Slack → FastAPI /webhooks/slack → Classify → Write to DB
- Each row is audit trail of what came from Slack + what was created

---

### 8. LISTING_NOTES TABLE
**Purpose:** Notes attached to listings (collaborative context)
**Status:** Active

| Column | Type | Key Properties |
|--------|------|-----------------|
| note_id | TEXT PRIMARY KEY | ULID format |
| listing_id | TEXT FK NOT NULL | References listings(listing_id) CASCADE |
| content | TEXT NOT NULL | Note text (1-5000 chars) |
| type | TEXT | general, agent, staff, etc. |
| created_by | TEXT | User ID who wrote it |
| created_at / updated_at | TIMESTAMPTZ | Audit trail |

**Indexes:**
- listing_id
- created_at
- type

---

### 9. TASK_NOTES TABLE
**Purpose:** Comments on individual tasks/activities (thread-like)
**Status:** Active but minimal usage

| Column | Type | Key Properties |
|--------|------|-----------------|
| note_id | TEXT PRIMARY KEY | ULID format |
| task_id | TEXT FK NOT NULL | References tasks(task_id) CASCADE |
| content | TEXT NOT NULL | Comment text (1-5000 chars) |
| author_id | TEXT NOT NULL | User ID |
| created_at / updated_at | TIMESTAMPTZ | Audit trail |

**Indexes:**
- task_id
- author_id
- created_at

---

## Deprecated/Archive Tables

### audit_log (DEPRECATED)
**Status:** Created in migration 003, noted as intentionally not implemented
- **Reason:** Audit trail feature not currently active
- **Schema:** event_id, entity_key, action, performed_by, timestamp, changes, content
- **Indexes:** entity_key, timestamp, action, performed_by
- **Note:** Would be recreated if audit feature is re-enabled

---

## Data Relationships Map

```
┌─────────────┐
│   STAFF     │
└──────┬──────┘
       │
       │ manages/assigned_staff_id
       │
       ├──────────────┬─────────────┐
       │              │             │
   ACTIVITIES   AGENT_TASKS   LISTING_ACKS
   (per listing)  (per realtor) (per listing)
       │              │             │
       └──────┬───────┴─────────────┘
              │
         LISTINGS
              │
         ┌────┴─────┐
         │           │
    LISTING_     LISTING_
    DETAILS      NOTES
    
┌──────────┐
│ REALTORS │
└────┬─────┘
     │
     │ associated_with
     │
  ACTIVITIES   AGENT_TASKS
  (realtor_id) (realtor_id)
  
┌────────────────────┐
│  SLACK_MESSAGES    │
│  (EVENT AUDIT)     │
└─────────────────────┘
     │ references
     │
     ├─→ created_listing_id → LISTINGS
     ├─→ created_task_id → ACTIVITIES or AGENT_TASKS
     └─→ classification → LangChain results
```

---

## Key Schema Patterns

### 1. Soft Deletes
All tables use `deleted_at TIMESTAMPTZ` instead of hard delete
- Allows audit trails and recovery
- Indexes filter with `WHERE deleted_at IS NULL`
- Example: `idx_activities_status` indexes only non-deleted records

### 2. Auto-Updated Timestamps
Every table has `created_at` and `updated_at`:
```sql
CREATE TRIGGER trigger_update_[table]_updated_at
    BEFORE UPDATE ON [table]
    FOR EACH ROW
    EXECUTE FUNCTION update_[table]_updated_at();
```

### 3. JSON Data Storage
- `inputs JSONB` - Task parameters going in
- `outputs JSONB` - Results coming out
- `classification JSONB` - Full LangChain classification result
- `metadata JSONB` - Flexible extension point

### 4. Status Constraints
Different status values by context:
- **Listings:** new, in_progress, completed
- **Activities/Agent_Tasks:** OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED
- **Staff/Realtors:** active, inactive, suspended (+ pending for realtors)
- **Slack_Messages:** pending, processed, failed, skipped

### 5. Row Level Security
All tables have `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` but NO POLICIES YET
- RLS is enabled but permissive (no restrictions applied)
- Ready for future permission rules

---

## Critical Path: Inbox → MyListings Workflow

This requires coordination between 4 tables:

### Step 1: NEW LISTING IN INBOX (unacknowledged)
```sql
SELECT listings, COUNT(activities) as task_count
FROM listings
LEFT JOIN activities ON activities.listing_id = listings.listing_id
WHERE NOT EXISTS (
    SELECT 1 FROM listing_acknowledgments 
    WHERE listing_acknowledgments.staff_id = current_user
      AND listing_acknowledgments.listing_id = listings.listing_id
)
AND listings.deleted_at IS NULL
```

### Step 2: STAFF CLICKS "ACKNOWLEDGE"
```sql
INSERT INTO listing_acknowledgments (listing_id, staff_id, acknowledged_at, acknowledged_from)
VALUES (?, current_user, NOW(), 'mobile')
ON CONFLICT DO NOTHING;  -- idempotent
```

### Step 3: LISTING NOW IN MY_LISTINGS
```sql
SELECT listings, activities, COUNT(*) as total_tasks, 
       COUNT(CASE WHEN status = 'DONE' THEN 1 END) as completed_tasks
FROM listings
JOIN listing_acknowledgments ON acknowledgments.listing_id = listings.listing_id
LEFT JOIN activities ON activities.listing_id = listings.listing_id
WHERE listing_acknowledgments.staff_id = current_user
  AND listings.deleted_at IS NULL
GROUP BY listings.listing_id
```

### Step 4: ALL ACTIVITIES DONE → LOGBOOK
```sql
-- Listing is ready for logbook when:
-- 1. Listing has acknowledgment from current user
-- 2. All activities are DONE (status = 'DONE')
-- 3. No open/claimed/in-progress activities
```

---

## Migration Order (Dependency Chain)

1. **001-002:** tasks, task_notes (initial foundation)
2. **003-005:** listings, listing_details, listing_notes, staff, realtors
3. **006-007:** listing_tasks, stray_tasks
4. **008-015:** slack_messages, various updates
5. **016:** RENAME tables: listing_tasks → activities, stray_tasks → agent_tasks
6. **017-020:** Add missing columns, simplify categories, create listing_acknowledgments

---

## Current Gaps & TODOs

1. **RLS Policies Not Implemented**
   - RLS is enabled but no actual policies restrict data access
   - Would need: staff can only see their own tasks, etc.

2. **No Audit Logging**
   - `audit_log` table exists but not used
   - Consider event-based logging if needed

3. **Activity Completion Logic**
   - Database schema supports it (status=DONE, completed_at)
   - UI layer must compute "all done" state

4. **Classification Routing**
   - slack_messages stores classification results
   - Backend FastAPI endpoint /classify consumes these and creates tasks

---

## Index Strategy Summary

| Table | Hot Queries | Index Strategy |
|-------|------------|-----------------|
| staff | by_role, by_status, by_slack | Non-deleted filtering |
| realtors | by_status, by_slack, territories | Array indexing + soft delete |
| listings | by_status, by_agent, by_date | Multi-field composite indexes |
| activities | by_listing, by_status, by_staff | Composite on frequent filters |
| agent_tasks | by_realtor, by_status, by_key | Composite on realtor+status |
| slack_messages | by_user, by_channel, by_status | Temporal + status filtering |
| listing_acks | by_staff, by_listing | Foreign key queries |

---

## Size Estimates (Per Table, Historical)

Based on typical operations center (50 listings, 300 activities, 30 staff):
- listings: ~50 rows
- activities: ~300 rows
- agent_tasks: ~100 rows
- staff: ~30 rows
- realtors: ~100 rows
- slack_messages: ~1000 rows (audit trail)
- listing_acknowledgments: ~50 rows

Total: ~1,600 rows = well within Supabase free tier

---

## Query Patterns Used by Swift App

### AllListings View
```sql
-- All listings (Inbox)
SELECT * FROM listings WHERE deleted_at IS NULL
ORDER BY created_at DESC

-- User's claimed listings (MyListings)
SELECT l.*, 
       (SELECT COUNT(*) FROM activities WHERE listing_id = l.listing_id AND deleted_at IS NULL) as activity_count,
       (SELECT COUNT(*) FROM activities WHERE listing_id = l.listing_id AND status = 'DONE' AND deleted_at IS NULL) as completed_count
FROM listings l
WHERE EXISTS (SELECT 1 FROM listing_acknowledgments WHERE listing_id = l.listing_id AND staff_id = ?)
AND l.deleted_at IS NULL
ORDER BY l.created_at DESC
```

### Activity/Task Listing
```sql
-- All activities for a listing
SELECT * FROM activities 
WHERE listing_id = ? AND deleted_at IS NULL
ORDER BY priority DESC, due_date ASC

-- All agent tasks for current realtor
SELECT * FROM agent_tasks
WHERE realtor_id = ? AND deleted_at IS NULL
ORDER BY priority DESC, due_date ASC
```

---

**Generated:** 2025-11-16
**Database:** Supabase PostgreSQL
**Tables:** 9 core + 2 supporting + 1 deprecated
**Migrations:** 021 total (001-020 + final batch)
