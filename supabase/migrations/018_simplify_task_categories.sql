-- Migration: Simplify task categories to admin/marketing/null only
-- Removes PHOTO, STAGING, INSPECTION, OTHER from valid values
-- Sets invalid categories to NULL

-- Step 1: Update activities table - set invalid categories to NULL
UPDATE activities
SET task_category = NULL
WHERE task_category NOT IN ('ADMIN', 'MARKETING');

-- Step 2: Update agent_tasks table - set invalid categories to NULL
UPDATE agent_tasks
SET task_category = NULL
WHERE task_category NOT IN ('ADMIN', 'MARKETING');

-- Step 3: Update constraint on activities table
ALTER TABLE activities
DROP CONSTRAINT IF EXISTS activities_task_category_check;

ALTER TABLE activities
ADD CONSTRAINT activities_task_category_check
CHECK (task_category IN ('ADMIN', 'MARKETING') OR task_category IS NULL);

-- Step 4: Update constraint on agent_tasks table
ALTER TABLE agent_tasks
DROP CONSTRAINT IF EXISTS agent_tasks_task_category_check;

ALTER TABLE agent_tasks
ADD CONSTRAINT agent_tasks_task_category_check
CHECK (task_category IN ('ADMIN', 'MARKETING') OR task_category IS NULL);

-- Add helpful comment
COMMENT ON COLUMN activities.task_category IS
'Task category: ADMIN, MARKETING, or NULL (uncategorized). Pre-set by backend for activities.';

COMMENT ON COLUMN agent_tasks.task_category IS
'Task category: ADMIN, MARKETING, or NULL (uncategorized). User-toggleable for tasks.';
