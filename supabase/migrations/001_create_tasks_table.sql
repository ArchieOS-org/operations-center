-- Create tasks table with indexes
-- Following Supabase/PostgreSQL best practices

CREATE TABLE IF NOT EXISTS tasks (
    task_id TEXT PRIMARY KEY,
    listing_id TEXT NOT NULL,
    name TEXT NOT NULL,
    task_category TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLAIMED', 'DONE', 'FAILED')),
    priority INTEGER DEFAULT 0 CHECK (priority >= 0 AND priority <= 10),
    visibility_group TEXT DEFAULT 'BOTH' CHECK (visibility_group IN ('BOTH', 'AGENT', 'MARKETING')),
    
    -- Assignments
    assignee_id TEXT,
    agent_id TEXT,
    
    -- Timestamps
    due_date TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Soft delete
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,
    
    -- Data
    inputs JSONB DEFAULT '{}',
    outputs JSONB DEFAULT '{}',
    
    -- Flags
    is_stray BOOLEAN DEFAULT FALSE
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_listing 
    ON tasks(listing_id) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_assignee 
    ON tasks(assignee_id, due_date) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_status 
    ON tasks(status, priority DESC) 
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_stray 
    ON tasks(agent_id, created_at) 
    WHERE is_stray = TRUE AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_category 
    ON tasks(task_category, is_stray, created_at);

-- Enable Row Level Security (optional)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
