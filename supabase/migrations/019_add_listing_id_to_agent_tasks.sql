-- Migration: Add optional listing_id to agent_tasks
-- Allows tasks to be assigned to listings

-- Add listing_id column (nullable - tasks can be standalone or assigned)
ALTER TABLE agent_tasks
ADD COLUMN listing_id UUID REFERENCES listings(listing_id) ON DELETE SET NULL;

-- Create index for performance
CREATE INDEX idx_agent_tasks_listing ON agent_tasks(listing_id);

-- Add helpful comment
COMMENT ON COLUMN agent_tasks.listing_id IS
'Optional assignment to a listing. NULL = standalone task, UUID = assigned to specific listing. Tasks can be moved between listings or made standalone.';
