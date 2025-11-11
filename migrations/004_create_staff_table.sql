-- Migration: Create staff table for internal team members
-- Created: 2025-11-11
-- Description: Separates staff (internal operations team) from realtors

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

-- Indexes for efficient querying
CREATE INDEX idx_staff_role ON staff(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_staff_status ON staff(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_staff_slack ON staff(slack_user_id) WHERE slack_user_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_staff_email ON staff(email) WHERE deleted_at IS NULL;

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_staff_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_staff_updated_at
    BEFORE UPDATE ON staff
    FOR EACH ROW
    EXECUTE FUNCTION update_staff_updated_at();

-- Enable Row Level Security
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- Comments for documentation
COMMENT ON TABLE staff IS 'Internal team members (admins, marketing, operations staff)';
COMMENT ON COLUMN staff.staff_id IS 'Unique identifier (ULID format)';
COMMENT ON COLUMN staff.role IS 'Staff role: admin, operations, marketing, support';
COMMENT ON COLUMN staff.slack_user_id IS 'Slack user ID for integration';
COMMENT ON COLUMN staff.status IS 'Account status: active, inactive, suspended';
COMMENT ON COLUMN staff.metadata IS 'Additional flexible data storage';
