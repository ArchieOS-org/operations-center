# Database Architecture Documentation

**Project**: La-Paz Operations Center
**Database**: Supabase PostgreSQL (Single Database)
**Last Updated**: 2025-11-11

---

## Overview

This database restructuring properly separates **staff** (internal operations team) from **realtors** (external agents/clients), splits tasks into **listing-specific** and **realtor-specific** types, and adds comprehensive **Slack message** tracking.

### Key Design Principles

✅ **Single Database Approach** - All tables in one PostgreSQL database (NOT multiple databases)
✅ **Proper User Separation** - Staff and realtors are completely separate tables
✅ **Task Type Clarity** - Listing tasks vs. stray tasks are distinct entities
✅ **Foreign Key Integrity** - Full referential integrity with CASCADE rules
✅ **Soft Deletes** - All main tables support soft deletion
✅ **Comprehensive Indexing** - Optimized for common query patterns

---

## Database Tables

### 1. **staff** - Internal Team Members

**Purpose**: Operations team, admins, marketing staff

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `staff_id` | TEXT | PRIMARY KEY | ULID identifier |
| `email` | TEXT | NOT NULL, UNIQUE | Email address |
| `name` | TEXT | NOT NULL | Full name |
| `role` | TEXT | NOT NULL, CHECK | Role: admin, operations, marketing, support |
| `slack_user_id` | TEXT | UNIQUE | Slack integration ID |
| `phone` | TEXT | NULL | Phone number |
| `status` | TEXT | NOT NULL, CHECK | Status: active, inactive, suspended |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Auto-updated timestamp |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |
| `metadata` | JSONB | DEFAULT '{}' | Additional flexible data |

**Indexes**:
- `idx_staff_role` ON `(role)` WHERE `deleted_at IS NULL`
- `idx_staff_status` ON `(status)` WHERE `deleted_at IS NULL`
- `idx_staff_slack` ON `(slack_user_id)` WHERE `slack_user_id IS NOT NULL AND deleted_at IS NULL`
- `idx_staff_email` ON `(email)` WHERE `deleted_at IS NULL`

**Triggers**: Auto-update `updated_at` on row modification

---

### 2. **realtors** - Real Estate Agents

**Purpose**: External agents/brokers who listings are for

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `realtor_id` | TEXT | PRIMARY KEY | ULID identifier |
| `email` | TEXT | NOT NULL, UNIQUE | Email address |
| `name` | TEXT | NOT NULL | Full name |
| `phone` | TEXT | NULL | Phone number |
| `license_number` | TEXT | UNIQUE | Real estate license number |
| `brokerage` | TEXT | NULL | Brokerage firm name |
| `slack_user_id` | TEXT | UNIQUE | Slack integration ID |
| `territories` | TEXT[] | NULL | Array of regions covered |
| `status` | TEXT | NOT NULL, CHECK | Status: active, inactive, suspended, pending |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Auto-updated timestamp |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |
| `metadata` | JSONB | DEFAULT '{}' | Additional flexible data |

**Indexes**:
- `idx_realtors_status` ON `(status)` WHERE `deleted_at IS NULL`
- `idx_realtors_slack` ON `(slack_user_id)` WHERE `slack_user_id IS NOT NULL AND deleted_at IS NULL`
- `idx_realtors_email` ON `(email)` WHERE `deleted_at IS NULL`
- `idx_realtors_license` ON `(license_number)` WHERE `license_number IS NOT NULL AND deleted_at IS NULL`
- `idx_realtors_brokerage` ON `(brokerage)` WHERE `brokerage IS NOT NULL AND deleted_at IS NULL`
- `idx_realtors_territories` ON `(territories)` USING GIN

---

### 3. **activities** - Property-Specific Tasks

**Purpose**: Tasks tied to specific listings

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `task_id` | TEXT | PRIMARY KEY | ULID identifier |
| `listing_id` | TEXT | NOT NULL, FK → listings | Listing reference |
| `realtor_id` | TEXT | NULL, FK → realtors | Realtor for this listing |
| `name` | TEXT | NOT NULL | Task name |
| `description` | TEXT | NULL | Task description |
| `task_category` | TEXT | NOT NULL, CHECK | Category: ADMIN, MARKETING, PHOTO, STAGING, INSPECTION, OTHER |
| `status` | TEXT | NOT NULL, CHECK | Status: OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED |
| `priority` | INTEGER | DEFAULT 0, CHECK (0-10) | Priority level |
| `visibility_group` | TEXT | DEFAULT 'BOTH', CHECK | Visibility: BOTH, AGENT, MARKETING |
| `assigned_staff_id` | TEXT | NULL, FK → staff | Staff assigned to task |
| `due_date` | TIMESTAMPTZ | NULL | Task due date |
| `claimed_at` | TIMESTAMPTZ | NULL | When claimed |
| `completed_at` | TIMESTAMPTZ | NULL | When completed |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Auto-updated timestamp |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |
| `deleted_by` | TEXT | NULL | Who deleted |
| `inputs` | JSONB | DEFAULT '{}' | Task inputs (JSON) |
| `outputs` | JSONB | DEFAULT '{}' | Task outputs (JSON) |

**Foreign Keys**:
- `listing_id` → `listings(listing_id)` ON DELETE CASCADE
- `realtor_id` → `realtors(realtor_id)` ON DELETE SET NULL
- `assigned_staff_id` → `staff(staff_id)` ON DELETE SET NULL

**Indexes**:
- `idx_activities_listing` ON `(listing_id)` WHERE `deleted_at IS NULL`
- `idx_activities_realtor` ON `(realtor_id)` WHERE `deleted_at IS NULL`
- `idx_activities_assigned_staff` ON `(assigned_staff_id, due_date)` WHERE `deleted_at IS NULL`
- `idx_activities_status` ON `(status, priority DESC)` WHERE `deleted_at IS NULL`
- `idx_activities_category` ON `(task_category)` WHERE `deleted_at IS NULL`
- `idx_activities_due_date` ON `(due_date)` WHERE `deleted_at IS NULL AND status != 'DONE'`
- `idx_activities_listing_status` ON `(listing_id, status, priority DESC)` WHERE `deleted_at IS NULL`

---

### 4. **agent_tasks** - Realtor-Specific Tasks

**Purpose**: Tasks for realtors NOT tied to a specific listing

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `task_id` | TEXT | PRIMARY KEY | ULID identifier |
| `realtor_id` | TEXT | NOT NULL, FK → realtors | Realtor this task is for |
| `task_key` | TEXT | NOT NULL | Task type key from classification |
| `name` | TEXT | NOT NULL | Task name |
| `description` | TEXT | NULL | Task description |
| `status` | TEXT | NOT NULL, CHECK | Status: OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED |
| `priority` | INTEGER | DEFAULT 0, CHECK (0-10) | Priority level |
| `assigned_staff_id` | TEXT | NULL, FK → staff | Staff helping the realtor |
| `due_date` | TIMESTAMPTZ | NULL | Task due date |
| `claimed_at` | TIMESTAMPTZ | NULL | When claimed |
| `completed_at` | TIMESTAMPTZ | NULL | When completed |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Auto-updated timestamp |
| `deleted_at` | TIMESTAMPTZ | NULL | Soft delete timestamp |
| `deleted_by` | TEXT | NULL | Who deleted |
| `inputs` | JSONB | DEFAULT '{}' | Task inputs (JSON) |
| `outputs` | JSONB | DEFAULT '{}' | Task outputs (JSON) |

**Foreign Keys**:
- `realtor_id` → `realtors(realtor_id)` ON DELETE CASCADE
- `assigned_staff_id` → `staff(staff_id)` ON DELETE SET NULL

**Indexes**:
- `idx_agent_tasks_realtor` ON `(realtor_id, created_at DESC)` WHERE `deleted_at IS NULL`
- `idx_agent_tasks_assigned_staff` ON `(assigned_staff_id, due_date)` WHERE `deleted_at IS NULL`
- `idx_agent_tasks_status` ON `(status, priority DESC)` WHERE `deleted_at IS NULL`
- `idx_agent_tasks_task_key` ON `(task_key)` WHERE `deleted_at IS NULL`
- `idx_agent_tasks_due_date` ON `(due_date)` WHERE `deleted_at IS NULL AND status != 'DONE'`
- `idx_agent_tasks_realtor_status` ON `(realtor_id, status, priority DESC)` WHERE `deleted_at IS NULL`

---

### 5. **slack_messages** - Slack Message Tracking

**Purpose**: Track Slack messages with classification and entity linkage

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `message_id` | TEXT | PRIMARY KEY | ULID identifier |
| `slack_user_id` | TEXT | NOT NULL | Who sent the message |
| `slack_channel_id` | TEXT | NOT NULL | Which channel |
| `slack_ts` | TEXT | NOT NULL, UNIQUE | Slack message timestamp (unique ID) |
| `slack_thread_ts` | TEXT | NULL | Thread timestamp if in thread |
| `message_text` | TEXT | NOT NULL | Message content |
| `classification` | JSONB | NOT NULL | Full classification result (JSON) |
| `message_type` | TEXT | NOT NULL | Classified type |
| `task_key` | TEXT | NULL | Task key if applicable |
| `group_key` | TEXT | NULL | Group key for categorization |
| `confidence` | NUMERIC(5,4) | CHECK (0-1) | Classification confidence |
| `created_listing_id` | TEXT | NULL, FK → listings | Listing created from message |
| `created_task_id` | TEXT | NULL | Task ID created (listing_task or stray_task) |
| `created_task_type` | TEXT | CHECK | Type: listing_task or stray_task |
| `received_at` | TIMESTAMPTZ | DEFAULT NOW() | When received |
| `processed_at` | TIMESTAMPTZ | NULL | When processed |
| `processing_status` | TEXT | DEFAULT 'pending', CHECK | Status: pending, processed, failed, skipped |
| `error_message` | TEXT | NULL | Error if failed |
| `metadata` | JSONB | DEFAULT '{}' | Additional data |

**Foreign Keys**:
- `created_listing_id` → `listings(listing_id)` ON DELETE SET NULL

**Indexes**:
- `idx_slack_messages_slack_user` ON `(slack_user_id, received_at DESC)`
- `idx_slack_messages_channel` ON `(slack_channel_id, received_at DESC)`
- `idx_slack_messages_ts` ON `(slack_ts)`
- `idx_slack_messages_thread` ON `(slack_thread_ts)` WHERE `slack_thread_ts IS NOT NULL`
- `idx_slack_messages_message_type` ON `(message_type)`
- `idx_slack_messages_task_key` ON `(task_key)` WHERE `task_key IS NOT NULL`
- `idx_slack_messages_status` ON `(processing_status, received_at DESC)`
- `idx_slack_messages_created_listing` ON `(created_listing_id)` WHERE `created_listing_id IS NOT NULL`
- `idx_slack_messages_created_task` ON `(created_task_id, created_task_type)` WHERE `created_task_id IS NOT NULL`

---

### 6. **listings** (Updated)

**Changes**: Added `realtor_id` foreign key column

```sql
ALTER TABLE listings ADD COLUMN realtor_id TEXT;
ALTER TABLE listings ADD CONSTRAINT fk_listings_realtor
    FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id) ON DELETE SET NULL;
CREATE INDEX idx_listings_realtor ON listings(realtor_id) WHERE deleted_at IS NULL;
```

---

## Entity Relationships

```
┌─────────────┐
│   staff     │
└──────┬──────┘
       │
       │ (assigned to)
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌──────────────┐  ┌──────────────┐
│activities │  │ agent_tasks  │
└──────┬───────┘  └──────┬───────┘
       │                  │
       │ (for)            │ (for)
       │                  │
       ▼                  ▼
┌──────────────┐    ┌──────────┐
│   listings   │────│ realtors │
└──────┬───────┘    └────┬─────┘
       │                  │
       │ (created from)   │
       ▼                  │
┌───────────────┐◄────────┘
│slack_messages │
└───────────────┘
```

**Key Relationships**:

1. **Staff → Tasks**: Staff can be assigned to both activities and agent_tasks
2. **Realtors → Listings**: Each listing has one realtor
3. **Realtors → Stray Tasks**: Stray tasks are always for a specific realtor
4. **Listings → Listing Tasks**: Listing tasks are tied to a specific listing (CASCADE delete)
5. **Slack Messages → All Entities**: Can create listings and tasks, tracks message history

---

## Common Query Patterns

### Get all tasks for a staff member
```sql
-- Listing tasks
SELECT * FROM activities
WHERE assigned_staff_id = 'staff_id_here'
  AND deleted_at IS NULL
ORDER BY due_date;

-- Stray tasks
SELECT * FROM agent_tasks
WHERE assigned_staff_id = 'staff_id_here'
  AND deleted_at IS NULL
ORDER BY due_date;
```

### Get all tasks for a realtor
```sql
-- Tasks for realtor's listings
SELECT lt.*, l.address_string
FROM activities lt
JOIN listings l ON lt.listing_id = l.listing_id
WHERE l.realtor_id = 'realtor_id_here'
  AND lt.deleted_at IS NULL
ORDER BY lt.priority DESC, lt.due_date;

-- Stray tasks for realtor
SELECT * FROM agent_tasks
WHERE realtor_id = 'realtor_id_here'
  AND deleted_at IS NULL
ORDER BY priority DESC, due_date;
```

### Get all tasks for a listing
```sql
SELECT lt.*, s.name AS assigned_staff_name
FROM activities lt
LEFT JOIN staff s ON lt.assigned_staff_id = s.staff_id
WHERE lt.listing_id = 'listing_id_here'
  AND lt.deleted_at IS NULL
ORDER BY lt.status, lt.priority DESC;
```

### Get Slack message history for a realtor
```sql
SELECT * FROM slack_messages
WHERE slack_user_id IN (
    SELECT slack_user_id
    FROM realtors
    WHERE realtor_id = 'realtor_id_here'
)
ORDER BY received_at DESC
LIMIT 100;
```

---

## Migration Path

### Apply Migrations Locally (Supabase CLI)

```bash
# Install Supabase CLI (if not already)
npm install supabase --save-dev

# Initialize Supabase (if not already done)
npx supabase init

# Link to remote Supabase project
npx supabase link --project-ref your-project-ref

# Apply migrations
npx supabase db push

# Or apply individual migration
psql -U postgres -h localhost -d postgres -f migrations/004_create_staff_table.sql
```

### Apply Migrations to Supabase Production

**Option 1: Supabase Dashboard**
1. Go to SQL Editor in Supabase Dashboard
2. Copy/paste each migration file content
3. Execute in order (004 → 005 → 006 → 007 → 008 → 009)

**Option 2: Supabase CLI**
```bash
npx supabase db push --linked
```

---

## Performance Considerations

### Indexing Strategy
- **Partial Indexes**: Most indexes use `WHERE deleted_at IS NULL` to exclude soft-deleted records
- **Composite Indexes**: Multi-column indexes for common filter combinations
- **GIN Indexes**: For array columns (`territories` in realtors)

### Query Optimization
- Always filter by `deleted_at IS NULL` in application queries
- Use pagination for list endpoints (offset + limit)
- Leverage indexes for sorting (e.g., `ORDER BY created_at DESC`)

### Expected Load
- **Staff**: ~10-100 records
- **Realtors**: ~100-1000 records
- **Listings**: ~1000-10000 records
- **Listing Tasks**: ~10000-100000 records
- **Stray Tasks**: ~1000-10000 records
- **Slack Messages**: ~100000+ records

---

## Security: Row Level Security (RLS)

All tables have RLS enabled. You must create policies for:

1. **Staff**: Admins can manage all, staff can view all, update own record
2. **Realtors**: Admins can manage, realtors can view all, update own record
3. **Listing Tasks**: Based on visibility_group and staff role
4. **Stray Tasks**: Realtor can view own, assigned staff can view assigned
5. **Slack Messages**: Admin only for full access

Example RLS policy:
```sql
-- Staff can view all staff members
CREATE POLICY "staff_view_all" ON staff
FOR SELECT USING (auth.role() = 'authenticated');

-- Staff can update own record
CREATE POLICY "staff_update_own" ON staff
FOR UPDATE USING (auth.uid() = staff_id);
```

---

## Backup and Recovery

### Automatic Backups
Supabase automatically backs up your database. Check Settings → Database → Backups.

### Manual Backup
```bash
pg_dump -h db.your-project.supabase.co -U postgres -d postgres > backup.sql
```

### Restore from Backup
```bash
psql -h db.your-project.supabase.co -U postgres -d postgres < backup.sql
```

---

## Monitoring

### Key Metrics to Track
- Table row counts
- Index usage statistics
- Slow queries (> 1 second)
- Foreign key constraint violations
- Soft delete ratio (deleted_at IS NOT NULL count)

### Supabase Dashboard
- **Database** → **Tables**: View table structure
- **Database** → **Extensions**: Enable pg_stat_statements for query analytics
- **Database** → **Roles**: Manage database users

---

## Next Steps

1. ✅ Apply all migration files to Supabase
2. ⏳ Complete database access layer (`backend/database/*.py`)
3. ⏳ Create API routers (`backend/routers/*.py`)
4. ⏳ Create Vercel entry points (`api/v1/*.py`)
5. ⏳ Test all CRUD operations
6. ⏳ Set up RLS policies
7. ⏳ Configure monitoring and alerts

**See `README_API.md` for API endpoint documentation**
**See `README_MIGRATION.md` for data migration from AWS DynamoDB**
