-- Migration 019: Drop deprecated tables
-- Removes old unused tables from previous architecture

-- ============================================================
-- DROP UNUSED TABLES
-- ============================================================

-- Drop old tasks table (replaced by agent_tasks and activities)
DROP TABLE IF EXISTS tasks CASCADE;

-- Drop old task_notes table (replaced by listing_notes)
DROP TABLE IF EXISTS task_notes CASCADE;

-- Drop listing_details table (unused - details integrated into listings table)
DROP TABLE IF EXISTS listing_details CASCADE;

-- Drop audit_log table (not implemented, no audit trail currently)
DROP TABLE IF EXISTS audit_log CASCADE;

-- ============================================================
-- VERIFICATION
-- ============================================================

-- The following tables should now exist:
-- - agent_tasks (renamed from stray_tasks)
-- - activities (renamed from listing_tasks)
-- - activity_items (newly created)
-- - listings
-- - listing_notes
-- - realtors
-- - staff
-- - slack_messages

COMMENT ON SCHEMA public IS 'Operations Center schema - cleaned up and aligned with Swift models';
