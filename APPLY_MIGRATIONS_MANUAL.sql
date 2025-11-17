-- ============================================================
-- CONSOLIDATED MIGRATIONS FOR MANUAL APPLICATION
-- ============================================================
-- This file consolidates migrations 003-017, 019 for manual execution
-- in the Supabase SQL Editor dashboard.
--
-- Instructions:
-- 1. Go to: https://supabase.com/dashboard/project/kukmshbkzlskyuacgzbo/sql
-- 2. Copy this entire file
-- 3. Paste into SQL Editor
-- 4. Click "Run" or press Cmd+Enter
-- 5. Verify success
--
-- Note: Migrations 001-002 are already applied remotely (skip those)
-- ============================================================

BEGIN;

-- ============================================================
-- MIGRATION 003: Create Listings Tables (FIXED)
-- ============================================================

-- Drop malformed audit_log if it exists
DROP TABLE IF EXISTS audit_log CASCADE;

-- NOTE: audit_log table is created here for schema completeness from migration 003,
-- but the audit trail feature is not currently implemented. This table is intentionally
-- removed in migration 019 below.
-- Create audit_log with correct schema
CREATE TABLE IF NOT EXISTS audit_log (
    event_id TEXT PRIMARY KEY,
    entity_key TEXT NOT NULL,
    action TEXT NOT NULL,
    performed_by TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changes JSONB,
    content TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log(entity_key);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_performed_by ON audit_log(performed_by);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE audit_log IS 'Audit trail for all entity changes';

-- ============================================================
-- MIGRATION 016: Rename Tables to Match Swift
-- ============================================================

-- Rename stray_tasks → agent_tasks
ALTER TABLE IF EXISTS stray_tasks RENAME TO agent_tasks;

-- Rename indexes
ALTER INDEX IF EXISTS idx_stray_tasks_realtor RENAME TO idx_agent_tasks_realtor;
ALTER INDEX IF EXISTS idx_stray_tasks_assigned_staff RENAME TO idx_agent_tasks_assigned_staff;
ALTER INDEX IF EXISTS idx_stray_tasks_status RENAME TO idx_agent_tasks_status;
ALTER INDEX IF EXISTS idx_stray_tasks_task_key RENAME TO idx_agent_tasks_task_key;
ALTER INDEX IF EXISTS idx_stray_tasks_due_date RENAME TO idx_agent_tasks_due_date;
ALTER INDEX IF EXISTS idx_stray_tasks_realtor_status RENAME TO idx_agent_tasks_realtor_status;

-- Rename trigger function
ALTER FUNCTION IF EXISTS update_stray_tasks_updated_at() RENAME TO update_agent_tasks_updated_at;

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_update_stray_tasks_updated_at ON agent_tasks;
CREATE TRIGGER trigger_update_agent_tasks_updated_at
    BEFORE UPDATE ON agent_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_tasks_updated_at();

COMMENT ON TABLE agent_tasks IS 'Agent tasks not tied to specific listings';

-- Rename listing_tasks → activities
ALTER TABLE IF EXISTS listing_tasks RENAME TO activities;

-- Rename indexes
ALTER INDEX IF EXISTS idx_listing_tasks_listing RENAME TO idx_activities_listing;
ALTER INDEX IF EXISTS idx_listing_tasks_realtor RENAME TO idx_activities_realtor;
ALTER INDEX IF EXISTS idx_listing_tasks_assigned_staff RENAME TO idx_activities_assigned_staff;
ALTER INDEX IF EXISTS idx_listing_tasks_status RENAME TO idx_activities_status;
ALTER INDEX IF EXISTS idx_listing_tasks_category RENAME TO idx_activities_category;
ALTER INDEX IF EXISTS idx_listing_tasks_due_date RENAME TO idx_activities_due_date;
ALTER INDEX IF EXISTS idx_listing_tasks_listing_status RENAME TO idx_activities_listing_status;

-- Rename trigger function
ALTER FUNCTION IF EXISTS update_listing_tasks_updated_at() RENAME TO update_activities_updated_at;

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_update_listing_tasks_updated_at ON activities;
CREATE TRIGGER trigger_update_activities_updated_at
    BEFORE UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION update_activities_updated_at();

COMMENT ON TABLE activities IS 'Property-specific activities tied to listings';

-- ============================================================
-- MIGRATION 017: Add task_category Column
-- ============================================================

-- Add task_category to agent_tasks
ALTER TABLE agent_tasks
ADD COLUMN IF NOT EXISTS task_category TEXT NOT NULL DEFAULT 'OTHER'
CHECK (task_category IN ('ADMIN', 'MARKETING', 'PHOTO', 'STAGING', 'INSPECTION', 'OTHER'));

CREATE INDEX IF NOT EXISTS idx_agent_tasks_category ON agent_tasks(task_category);

COMMENT ON COLUMN agent_tasks.task_category IS 'Category: ADMIN, MARKETING, PHOTO, STAGING, INSPECTION, OTHER';
COMMENT ON COLUMN agent_tasks.task_key IS 'DEPRECATED: Use task_category instead';

-- ============================================================
-- MIGRATION 019: Cleanup Deprecated Tables
-- ============================================================

-- Drop old unused tables
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS task_notes CASCADE;
DROP TABLE IF EXISTS listing_details CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;  -- Not implemented, cleaning up

COMMENT ON SCHEMA public IS 'Operations Center schema - cleaned up and aligned with Swift models';

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Verify tables exist
DO $$
BEGIN
    ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agent_tasks'),
        'agent_tasks table must exist';
    ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'activities'),
        'activities table must exist';
    ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'listings'),
        'listings table must exist';
    ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff'),
        'staff table must exist';
    ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'realtors'),
        'realtors table must exist';

    RAISE NOTICE 'All critical tables verified successfully';
END $$;

COMMIT;

-- ============================================================
-- SUCCESS
-- ============================================================
-- If you see this message without errors, migrations applied successfully!
-- Next step: Mark migrations as applied in Supabase CLI:
--   supabase migration repair 003 016 017 019 --status applied
-- ============================================================
