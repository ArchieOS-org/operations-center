-- Migration 016: Rename tables to match Swift model expectations
-- renames stray_tasks → agent_tasks and listing_tasks → activities

-- ============================================================
-- RENAME: stray_tasks → agent_tasks
-- ============================================================

-- Rename the main table
ALTER TABLE IF EXISTS stray_tasks RENAME TO agent_tasks;

-- Rename all indexes
ALTER INDEX IF EXISTS idx_stray_tasks_realtor RENAME TO idx_agent_tasks_realtor;
ALTER INDEX IF EXISTS idx_stray_tasks_assigned_staff RENAME TO idx_agent_tasks_assigned_staff;
ALTER INDEX IF EXISTS idx_stray_tasks_status RENAME TO idx_agent_tasks_status;
ALTER INDEX IF EXISTS idx_stray_tasks_task_key RENAME TO idx_agent_tasks_task_key;
ALTER INDEX IF EXISTS idx_stray_tasks_due_date RENAME TO idx_agent_tasks_due_date;
ALTER INDEX IF EXISTS idx_stray_tasks_realtor_status RENAME TO idx_agent_tasks_realtor_status;

-- Rename the trigger function
ALTER FUNCTION IF EXISTS update_stray_tasks_updated_at() RENAME TO update_agent_tasks_updated_at;

-- Recreate the trigger with new name
DROP TRIGGER IF EXISTS trigger_update_stray_tasks_updated_at ON agent_tasks;
CREATE TRIGGER trigger_update_agent_tasks_updated_at
    BEFORE UPDATE ON agent_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_tasks_updated_at();

-- Update table comment
COMMENT ON TABLE agent_tasks IS 'Agent tasks not tied to specific listings - for realtor management and admin work';

-- ============================================================
-- RENAME: listing_tasks → activities
-- ============================================================

-- Rename the main table
ALTER TABLE IF EXISTS listing_tasks RENAME TO activities;

-- Rename all indexes
ALTER INDEX IF EXISTS idx_listing_tasks_listing RENAME TO idx_activities_listing;
ALTER INDEX IF EXISTS idx_listing_tasks_realtor RENAME TO idx_activities_realtor;
ALTER INDEX IF EXISTS idx_listing_tasks_assigned_staff RENAME TO idx_activities_assigned_staff;
ALTER INDEX IF EXISTS idx_listing_tasks_status RENAME TO idx_activities_status;
ALTER INDEX IF EXISTS idx_listing_tasks_category RENAME TO idx_activities_category;
ALTER INDEX IF EXISTS idx_listing_tasks_due_date RENAME TO idx_activities_due_date;
ALTER INDEX IF EXISTS idx_listing_tasks_listing_status RENAME TO idx_activities_listing_status;

-- Rename the trigger function
ALTER FUNCTION IF EXISTS update_listing_tasks_updated_at() RENAME TO update_activities_updated_at;

-- Recreate the trigger with new name
DROP TRIGGER IF EXISTS trigger_update_listing_tasks_updated_at ON activities;
CREATE TRIGGER trigger_update_activities_updated_at
    BEFORE UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION update_activities_updated_at();

-- Update table comment
COMMENT ON TABLE activities IS 'Property-specific activities tied to listings - coordinated workflows for listing preparation and marketing';
