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
