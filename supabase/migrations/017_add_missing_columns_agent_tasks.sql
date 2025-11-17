-- Migration 017: Add missing task_category column to agent_tasks
-- Enables category toggle feature for agent task classification

-- ============================================================
-- ADD task_category TO agent_tasks
-- ============================================================

-- Add column with check constraint matching Swift TaskCategory enum
ALTER TABLE agent_tasks
ADD COLUMN IF NOT EXISTS task_category TEXT NOT NULL DEFAULT 'OTHER'
CHECK (task_category IN ('ADMIN', 'MARKETING', 'PHOTO', 'STAGING', 'INSPECTION', 'OTHER'));

-- Create index for category filtering
CREATE INDEX IF NOT EXISTS idx_agent_tasks_category ON agent_tasks(task_category);

-- Add comment for documentation
COMMENT ON COLUMN agent_tasks.task_category IS 'Category classification: ADMIN, MARKETING, PHOTO, STAGING, INSPECTION, OTHER';

-- Note: task_key column exists but is deprecated - kept for backward compatibility
COMMENT ON COLUMN agent_tasks.task_key IS 'DEPRECATED: Use task_category instead. Maintained for historical data only.';
