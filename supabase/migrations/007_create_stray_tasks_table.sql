-- Migration: Create stray_tasks table for realtor-specific tasks
-- Created: 2025-11-11
-- Description: Tasks for realtors that are not tied to specific listings (replaces tasks where is_stray = TRUE)

CREATE TABLE IF NOT EXISTS stray_tasks (
    task_id TEXT PRIMARY KEY,
    realtor_id TEXT NOT NULL,
    task_key TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLAIMED', 'IN_PROGRESS', 'DONE', 'FAILED', 'CANCELLED')),
    priority INTEGER NOT NULL DEFAULT 0 CHECK (priority >= 0 AND priority <= 10),

    -- Staff assignment (who is helping the realtor)
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
    CONSTRAINT fk_stray_tasks_realtor FOREIGN KEY (realtor_id)
        REFERENCES realtors(realtor_id) ON DELETE CASCADE,
    CONSTRAINT fk_stray_tasks_assigned_staff FOREIGN KEY (assigned_staff_id)
        REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Indexes for efficient querying
CREATE INDEX idx_stray_tasks_realtor ON stray_tasks(realtor_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_stray_tasks_assigned_staff ON stray_tasks(assigned_staff_id, due_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_stray_tasks_status ON stray_tasks(status, priority DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_stray_tasks_task_key ON stray_tasks(task_key) WHERE deleted_at IS NULL;
CREATE INDEX idx_stray_tasks_due_date ON stray_tasks(due_date) WHERE deleted_at IS NULL AND status != 'DONE';
CREATE INDEX idx_stray_tasks_realtor_status ON stray_tasks(realtor_id, status, priority DESC) WHERE deleted_at IS NULL;

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stray_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stray_tasks_updated_at
    BEFORE UPDATE ON stray_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_stray_tasks_updated_at();

-- Enable Row Level Security
ALTER TABLE stray_tasks ENABLE ROW LEVEL SECURITY;

-- Comments for documentation
COMMENT ON TABLE stray_tasks IS 'Realtor-specific tasks not tied to a listing (e.g., general agent support)';
COMMENT ON COLUMN stray_tasks.task_id IS 'Unique identifier (ULID format)';
COMMENT ON COLUMN stray_tasks.realtor_id IS 'Realtor this task is for (required)';
COMMENT ON COLUMN stray_tasks.task_key IS 'Task type key from classification system';
COMMENT ON COLUMN stray_tasks.assigned_staff_id IS 'Staff member assigned to help the realtor';
COMMENT ON COLUMN stray_tasks.inputs IS 'Task input parameters (JSON)';
COMMENT ON COLUMN stray_tasks.outputs IS 'Task completion results (JSON)';
