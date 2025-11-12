-- Migration 010: Create staff and realtors tables (no dependencies)
-- These tables have no foreign key dependencies on other tables

-- ============================================================
-- Staff Table (Internal Team Members)
-- ============================================================

CREATE TABLE IF NOT EXISTS staff (
    staff_id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'operations', 'marketing', 'support')),
    slack_user_id TEXT UNIQUE,
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for staff table
CREATE INDEX IF NOT EXISTS idx_staff_role ON staff(role) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_status ON staff(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_slack_user ON staff(slack_user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_email ON staff(email) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_staff_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_staff_updated_at') THEN
        CREATE TRIGGER trigger_staff_updated_at
            BEFORE UPDATE ON staff
            FOR EACH ROW
            EXECUTE FUNCTION update_staff_updated_at();
    END IF;
END $$;

-- ============================================================
-- Realtors Table (External Real Estate Agents)
-- ============================================================

CREATE TABLE IF NOT EXISTS realtors (
    realtor_id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    phone TEXT,
    license_number TEXT UNIQUE,
    brokerage TEXT,
    slack_user_id TEXT UNIQUE,
    territories TEXT[],
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for realtors table
CREATE INDEX IF NOT EXISTS idx_realtors_status ON realtors(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_realtors_slack_user ON realtors(slack_user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_realtors_email ON realtors(email) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_realtors_license ON realtors(license_number) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_realtors_brokerage ON realtors(brokerage) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_realtors_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_realtors_updated_at') THEN
        CREATE TRIGGER trigger_realtors_updated_at
            BEFORE UPDATE ON realtors
            FOR EACH ROW
            EXECUTE FUNCTION update_realtors_updated_at();
    END IF;
END $$;

-- Comments
COMMENT ON TABLE staff IS 'Internal staff members (admin, operations, marketing, support)';
COMMENT ON TABLE realtors IS 'External real estate agents and brokers';
-- Migration 011: Create listings table if it doesn't exist
-- This is a simplified version that creates basic listings table

CREATE TABLE IF NOT EXISTS listings (
    listing_id TEXT PRIMARY KEY,
    address_string TEXT,
    status TEXT,
    assignee TEXT,
    agent_id TEXT,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listings_created ON listings(created_at) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_listings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_listings_updated_at') THEN
        CREATE TRIGGER trigger_listings_updated_at
            BEFORE UPDATE ON listings
            FOR EACH ROW
            EXECUTE FUNCTION update_listings_updated_at();
    END IF;
END $$;
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
-- Migration 013: Create slack_messages table
-- No dependencies on other new tables

CREATE TABLE IF NOT EXISTS slack_messages (
    message_id TEXT PRIMARY KEY,
    slack_user_id TEXT NOT NULL,
    slack_ts TEXT NOT NULL UNIQUE,
    message_text TEXT NOT NULL,
    classification JSONB NOT NULL,
    created_listing_id TEXT,
    created_task_id TEXT,
    created_task_type TEXT CHECK (created_task_type IN ('listing_task', 'stray_task')),
    processing_status TEXT NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processed', 'failed', 'skipped')),
    error_message TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes for slack_messages
CREATE INDEX IF NOT EXISTS idx_slack_messages_user ON slack_messages(slack_user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_status ON slack_messages(processing_status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_ts ON slack_messages(slack_ts) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_created_listing ON slack_messages(created_listing_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_created_task ON slack_messages(created_task_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_created_at ON slack_messages(created_at) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_slack_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_slack_messages_updated_at') THEN
        CREATE TRIGGER trigger_slack_messages_updated_at
            BEFORE UPDATE ON slack_messages
            FOR EACH ROW
            EXECUTE FUNCTION update_slack_messages_updated_at();
    END IF;
END $$;

COMMENT ON TABLE slack_messages IS 'Tracks Slack messages with classification and processing status';
-- Migration 014: Add realtor_id column to listings table
-- Depends on: realtors table

-- Add realtor_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'listings'
        AND column_name = 'realtor_id'
    ) THEN
        ALTER TABLE listings ADD COLUMN realtor_id TEXT;
    END IF;
END $$;

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_listings_realtor'
    ) THEN
        ALTER TABLE listings ADD CONSTRAINT fk_listings_realtor
            FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id) ON DELETE SET NULL;
    END IF;
END $$;

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_listings_realtor ON listings(realtor_id) WHERE deleted_at IS NULL;

COMMENT ON COLUMN listings.realtor_id IS 'Foreign key reference to realtors table';
