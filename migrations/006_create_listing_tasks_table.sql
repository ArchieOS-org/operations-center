-- Migration: Create listing_tasks table for property-specific tasks
-- Created: 2025-11-11
-- Description: Tasks tied to specific listings (replaces tasks where is_stray = FALSE)

CREATE TABLE IF NOT EXISTS listing_tasks (
    task_id TEXT PRIMARY KEY,
    listing_id TEXT NOT NULL,
    realtor_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    task_category TEXT NOT NULL CHECK (task_category IN ('ADMIN', 'MARKETING', 'PHOTO', 'STAGING', 'INSPECTION', 'OTHER')),
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLAIMED', 'IN_PROGRESS', 'DONE', 'FAILED', 'CANCELLED')),
    priority INTEGER NOT NULL DEFAULT 0 CHECK (priority >= 0 AND priority <= 10),
    visibility_group TEXT NOT NULL DEFAULT 'BOTH' CHECK (visibility_group IN ('BOTH', 'AGENT', 'MARKETING')),

    -- Staff assignment (who is working on this)
    assigned_staff_id TEXT,

    -- Timestamps
    due_date TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,

    -- JSON data
    inputs JSONB DEFAULT '{}'::jsonb,
    outputs JSONB DEFAULT '{}'::jsonb,

    -- Foreign key constraints
    CONSTRAINT fk_listing_tasks_listing FOREIGN KEY (listing_id)
        REFERENCES listings(listing_id) ON DELETE CASCADE,
    CONSTRAINT fk_listing_tasks_realtor FOREIGN KEY (realtor_id)
        REFERENCES realtors(realtor_id) ON DELETE SET NULL,
    CONSTRAINT fk_listing_tasks_assigned_staff FOREIGN KEY (assigned_staff_id)
        REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Indexes for efficient querying
CREATE INDEX idx_listing_tasks_listing ON listing_tasks(listing_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_listing_tasks_realtor ON listing_tasks(realtor_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_listing_tasks_assigned_staff ON listing_tasks(assigned_staff_id, due_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_listing_tasks_status ON listing_tasks(status, priority DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_listing_tasks_category ON listing_tasks(task_category) WHERE deleted_at IS NULL;
CREATE INDEX idx_listing_tasks_due_date ON listing_tasks(due_date) WHERE deleted_at IS NULL AND status != 'DONE';
CREATE INDEX idx_listing_tasks_listing_status ON listing_tasks(listing_id, status, priority DESC) WHERE deleted_at IS NULL;

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_listing_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_listing_tasks_updated_at
    BEFORE UPDATE ON listing_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_listing_tasks_updated_at();

-- Enable Row Level Security
ALTER TABLE listing_tasks ENABLE ROW LEVEL SECURITY;

-- Comments for documentation
COMMENT ON TABLE listing_tasks IS 'Tasks tied to specific property listings';
COMMENT ON COLUMN listing_tasks.task_id IS 'Unique identifier (ULID format)';
COMMENT ON COLUMN listing_tasks.listing_id IS 'Reference to the listing this task is for';
COMMENT ON COLUMN listing_tasks.realtor_id IS 'Realtor associated with this listing';
COMMENT ON COLUMN listing_tasks.task_category IS 'Category: ADMIN, MARKETING, PHOTO, STAGING, INSPECTION, OTHER';
COMMENT ON COLUMN listing_tasks.assigned_staff_id IS 'Staff member assigned to complete this task';
COMMENT ON COLUMN listing_tasks.visibility_group IS 'Who can see this task: BOTH, AGENT, MARKETING';
COMMENT ON COLUMN listing_tasks.inputs IS 'Task input parameters (JSON)';
COMMENT ON COLUMN listing_tasks.outputs IS 'Task completion results (JSON)';
