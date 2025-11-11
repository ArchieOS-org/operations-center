-- Migration 012: Create listing_tasks and stray_tasks tables
-- Depends on: staff, realtors, listings tables

-- ============================================================
-- Listing Tasks Table (Property-Specific Tasks)
-- ============================================================

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
    assigned_staff_id TEXT,
    due_date TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,
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

-- Indexes for listing_tasks
CREATE INDEX IF NOT EXISTS idx_listing_tasks_listing ON listing_tasks(listing_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listing_tasks_realtor ON listing_tasks(realtor_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listing_tasks_staff ON listing_tasks(assigned_staff_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listing_tasks_status ON listing_tasks(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listing_tasks_category ON listing_tasks(task_category) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listing_tasks_due_date ON listing_tasks(due_date) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_listing_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_listing_tasks_updated_at') THEN
        CREATE TRIGGER trigger_listing_tasks_updated_at
            BEFORE UPDATE ON listing_tasks
            FOR EACH ROW
            EXECUTE FUNCTION update_listing_tasks_updated_at();
    END IF;
END $$;

-- ============================================================
-- Stray Tasks Table (Realtor-Specific Tasks)
-- ============================================================

CREATE TABLE IF NOT EXISTS stray_tasks (
    task_id TEXT PRIMARY KEY,
    realtor_id TEXT NOT NULL,
    task_key TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLAIMED', 'IN_PROGRESS', 'DONE', 'FAILED', 'CANCELLED')),
    priority INTEGER NOT NULL DEFAULT 0 CHECK (priority >= 0 AND priority <= 10),
    assigned_staff_id TEXT,
    due_date TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    deleted_by TEXT,
    notes TEXT,
    inputs JSONB DEFAULT '{}'::jsonb,
    outputs JSONB DEFAULT '{}'::jsonb,

    -- Foreign key constraints
    CONSTRAINT fk_stray_tasks_realtor FOREIGN KEY (realtor_id)
        REFERENCES realtors(realtor_id) ON DELETE CASCADE,
    CONSTRAINT fk_stray_tasks_assigned_staff FOREIGN KEY (assigned_staff_id)
        REFERENCES staff(staff_id) ON DELETE SET NULL,

    -- Unique constraint on realtor_id + task_key
    CONSTRAINT uq_stray_tasks_realtor_key UNIQUE (realtor_id, task_key)
);

-- Indexes for stray_tasks
CREATE INDEX IF NOT EXISTS idx_stray_tasks_realtor ON stray_tasks(realtor_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_stray_tasks_staff ON stray_tasks(assigned_staff_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_stray_tasks_status ON stray_tasks(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_stray_tasks_task_key ON stray_tasks(task_key) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_stray_tasks_due_date ON stray_tasks(due_date) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_stray_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_stray_tasks_updated_at') THEN
        CREATE TRIGGER trigger_stray_tasks_updated_at
            BEFORE UPDATE ON stray_tasks
            FOR EACH ROW
            EXECUTE FUNCTION update_stray_tasks_updated_at();
    END IF;
END $$;

-- Comments
COMMENT ON TABLE listing_tasks IS 'Tasks tied to specific property listings';
COMMENT ON TABLE stray_tasks IS 'Realtor-specific tasks not tied to any listing';
