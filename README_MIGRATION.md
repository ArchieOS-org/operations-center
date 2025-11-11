# Database Migration Guide

**Project**: La-Paz Operations Center
**Migration**: AWS DynamoDB → Supabase PostgreSQL
**Last Updated**: 2025-11-11

---

## Overview

This guide covers applying the new database schema to Supabase. **Note**: No data migration from AWS DynamoDB is needed as per your requirements - you're starting fresh with the new structure.

---

## Prerequisites

1. ✅ Supabase account and project created
2. ✅ Supabase project URL and API keys
3. ✅ PostgreSQL client (psql) or Supabase CLI installed
4. ✅ Environment variables configured

---

## Migration Files

Located in `migrations/` directory:

1. `004_create_staff_table.sql` - Internal team members table
2. `005_create_realtors_table.sql` - Real estate agents table
3. `006_create_listing_tasks_table.sql` - Property-specific tasks
4. `007_create_stray_tasks_table.sql` - Realtor-specific tasks
5. `008_create_slack_messages_table.sql` - Slack message tracking
6. `009_update_listings_table.sql` - Add realtor reference to existing listings table

**Total**: 6 migration files

---

## Method 1: Supabase Dashboard (Recommended for Beginners)

### Step 1: Access SQL Editor
1. Go to [app.supabase.com](https://app.supabase.com)
2. Select your project
3. Navigate to **SQL Editor** in the left sidebar

### Step 2: Apply Migrations in Order

For each migration file (004 → 009), do the following:

1. Open the migration file locally (e.g., `migrations/004_create_staff_table.sql`)
2. Copy the entire SQL content
3. In Supabase SQL Editor, create a new query
4. Paste the SQL content
5. Click **Run** button
6. Verify success message appears
7. Repeat for the next file

**Order matters!** Run in sequence: 004, 005, 006, 007, 008, 009

### Step 3: Verify Tables Created

1. Go to **Table Editor** in Supabase Dashboard
2. Verify all new tables appear:
   - ✅ `staff`
   - ✅ `realtors`
   - ✅ `listing_tasks`
   - ✅ `stray_tasks`
   - ✅ `slack_messages`
3. Check `listings` table has new `realtor_id` column

---

## Method 2: Supabase CLI (Recommended for Developers)

### Step 1: Install Supabase CLI

```bash
# Using npm
npm install -g supabase

# Or using Homebrew (macOS)
brew install supabase/tap/supabase
```

### Step 2: Login to Supabase

```bash
supabase login
```

### Step 3: Link to Your Project

```bash
# Get your project ref from Supabase dashboard URL
# Example: https://app.supabase.com/project/abcdefghijklmnop
supabase link --project-ref abcdefghijklmnop
```

### Step 4: Apply Migrations

```bash
# From project root directory
supabase db push
```

This command will:
- Detect all new migration files in `migrations/`
- Apply them to your linked Supabase project in order
- Show success/error messages for each

### Step 5: Verify

```bash
# List all tables
supabase db list

# Or connect to database directly
supabase db connect
```

---

## Method 3: Direct PostgreSQL Connection

### Step 1: Get Connection String

1. Go to Supabase Dashboard → **Settings** → **Database**
2. Copy the connection string (choose **Transaction** pooler)
3. Replace `[YOUR-PASSWORD]` with your database password

Example:
```
postgres://postgres.abcdefghijklmnop:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

### Step 2: Apply Each Migration

```bash
# Set connection string
export SUPABASE_DB_URL="postgres://postgres.abcdefghijklmnop:password@..."

# Apply migrations in order
psql $SUPABASE_DB_URL -f migrations/004_create_staff_table.sql
psql $SUPABASE_DB_URL -f migrations/005_create_realtors_table.sql
psql $SUPABASE_DB_URL -f migrations/006_create_listing_tasks_table.sql
psql $SUPABASE_DB_URL -f migrations/007_create_stray_tasks_table.sql
psql $SUPABASE_DB_URL -f migrations/008_create_slack_messages_table.sql
psql $SUPABASE_DB_URL -f migrations/009_update_listings_table.sql
```

### Step 3: Verify

```bash
psql $SUPABASE_DB_URL -c "\dt"
```

Should show all tables including new ones.

---

## Post-Migration Steps

### 1. Configure Row Level Security (RLS)

All tables have RLS enabled but no policies yet. Create policies based on your auth setup:

**Example: Staff table policies**

```sql
-- Staff can view all staff members
CREATE POLICY "staff_select_all" ON staff
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Admins can insert staff
CREATE POLICY "admin_insert_staff" ON staff
  FOR INSERT
  WITH CHECK (
    auth.jwt() ->> 'role' = 'admin'
  );

-- Admins can update staff
CREATE POLICY "admin_update_staff" ON staff
  FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

-- Admins can delete staff
CREATE POLICY "admin_delete_staff" ON staff
  FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');
```

Apply similar policies for all tables based on your permission model.

### 2. Seed Initial Data (Optional)

Create staff and realtor records:

```sql
-- Insert admin staff member
INSERT INTO staff (staff_id, email, name, role, status)
VALUES (
  '01HWQK0000ADMIN0000000000',
  'admin@yourdomain.com',
  'System Admin',
  'admin',
  'active'
);

-- Insert sample realtor
INSERT INTO realtors (realtor_id, email, name, status)
VALUES (
  '01HWQK0000REALTOR0000000',
  'agent@realty.com',
  'Sample Agent',
  'active'
);
```

### 3. Update Environment Variables

Update `.env` with Supabase credentials:

```bash
# Supabase Configuration
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_KEY=your-service-role-key-here

# Keep existing vars
# ... other variables
```

### 4. Test Database Connections

Run a simple query to verify connection works:

```python
from backend.database.supabase_client import get_supabase_client

db = get_supabase_client()
response = db.table("staff").select("*").limit(1).execute()
print(f"✅ Connected! Found {len(response.data)} records")
```

---

## Rollback Procedure

If you need to rollback the migration:

### Option 1: Drop Tables (Clean Slate)

```sql
-- Drop tables in reverse order (respects foreign keys)
DROP TABLE IF EXISTS slack_messages CASCADE;
DROP TABLE IF EXISTS stray_tasks CASCADE;
DROP TABLE IF EXISTS listing_tasks CASCADE;
DROP TABLE IF EXISTS realtors CASCADE;
DROP TABLE IF EXISTS staff CASCADE;

-- Remove column from listings
ALTER TABLE listings DROP COLUMN IF EXISTS realtor_id;
```

### Option 2: Use Supabase Point-in-Time Recovery

1. Go to Supabase Dashboard → **Settings** → **Database** → **Backups**
2. Choose a backup from before the migration
3. Click **Restore**

**Note**: This will restore the ENTIRE database to that point in time.

---

## Verifying Migration Success

### Checklist

- [ ] All 6 migration files applied without errors
- [ ] `staff` table exists with correct columns
- [ ] `realtors` table exists with correct columns
- [ ] `listing_tasks` table exists with foreign keys to listings, realtors, staff
- [ ] `stray_tasks` table exists with foreign keys to realtors, staff
- [ ] `slack_messages` table exists with foreign key to listings
- [ ] `listings` table has new `realtor_id` column
- [ ] All indexes created (check with `\di` in psql)
- [ ] All triggers created for `updated_at` columns
- [ ] RLS enabled on all tables
- [ ] No data loss on existing `listings`, `tasks`, `task_notes` tables

### Verification Queries

```sql
-- Check all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('staff', 'realtors', 'listing_tasks', 'stray_tasks', 'slack_messages')
ORDER BY table_name;

-- Check foreign key constraints
SELECT
  tc.table_name,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('listing_tasks', 'stray_tasks', 'slack_messages', 'listings')
ORDER BY tc.table_name, tc.constraint_name;

-- Check indexes exist
SELECT
  tablename,
  indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('staff', 'realtors', 'listing_tasks', 'stray_tasks', 'slack_messages')
ORDER BY tablename, indexname;

-- Count rows (should be 0 for new tables)
SELECT 'staff' as table_name, COUNT(*) as row_count FROM staff
UNION ALL
SELECT 'realtors', COUNT(*) FROM realtors
UNION ALL
SELECT 'listing_tasks', COUNT(*) FROM listing_tasks
UNION ALL
SELECT 'stray_tasks', COUNT(*) FROM stray_tasks
UNION ALL
SELECT 'slack_messages', COUNT(*) FROM slack_messages;
```

---

## Troubleshooting

### Error: "relation already exists"

**Cause**: Table was already created in a previous migration attempt.

**Solution**:
```sql
-- Drop the specific table and re-run migration
DROP TABLE IF EXISTS staff CASCADE;
-- Then re-run the migration file
```

### Error: "foreign key constraint violation"

**Cause**: Migration files run out of order.

**Solution**: Drop all new tables and re-run in correct order (004 → 009).

### Error: "permission denied"

**Cause**: Using anon key instead of service role key.

**Solution**: Use service role key for migrations:
```bash
export SUPABASE_KEY="your-service-role-key"
```

### Migration Runs But No Tables Appear

**Cause**: Connected to wrong database or project.

**Solution**: Verify project ref and connection string are correct.

---

## Performance Optimization Post-Migration

### 1. Analyze Tables

After migration and initial data insertion:

```sql
ANALYZE staff;
ANALYZE realtors;
ANALYZE listing_tasks;
ANALYZE stray_tasks;
ANALYZE slack_messages;
ANALYZE listings;
```

This updates PostgreSQL statistics for query optimization.

### 2. Monitor Index Usage

After running the application for a while:

```sql
-- Check unused indexes
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan = 0
  AND indexname NOT LIKE '%_pkey';
```

Drop unused indexes to save space.

### 3. Enable pgStatStatements Extension

For query performance monitoring:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

---

## Next Steps After Migration

1. ✅ Apply all migration files
2. ✅ Configure RLS policies
3. ⏳ Seed initial data (staff, realtors)
4. ⏳ Update API code to use new tables
5. ⏳ Test all CRUD operations
6. ⏳ Update Slack webhook integration
7. ⏳ Deploy to production
8. ⏳ Monitor performance and adjust indexes

**See `README_DATABASE.md` for complete schema documentation**
**See `README_API.md` for API endpoint documentation**
**See `IMPLEMENTATION_STATUS.md` for current implementation status**
