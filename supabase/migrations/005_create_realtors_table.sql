-- Migration: Create realtors table for real estate agents
-- Created: 2025-11-11
-- Description: Separates realtors (external agents/brokers) from staff

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

-- Indexes for efficient querying
CREATE INDEX idx_realtors_status ON realtors(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_realtors_slack ON realtors(slack_user_id) WHERE slack_user_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_realtors_email ON realtors(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_realtors_license ON realtors(license_number) WHERE license_number IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_realtors_brokerage ON realtors(brokerage) WHERE brokerage IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_realtors_territories ON realtors USING GIN(territories);

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_realtors_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_realtors_updated_at
    BEFORE UPDATE ON realtors
    FOR EACH ROW
    EXECUTE FUNCTION update_realtors_updated_at();

-- Enable Row Level Security
ALTER TABLE realtors ENABLE ROW LEVEL SECURITY;

-- Comments for documentation
COMMENT ON TABLE realtors IS 'Real estate agents and brokers (external clients)';
COMMENT ON COLUMN realtors.realtor_id IS 'Unique identifier (ULID format)';
COMMENT ON COLUMN realtors.license_number IS 'Real estate license number';
COMMENT ON COLUMN realtors.brokerage IS 'Brokerage firm name';
COMMENT ON COLUMN realtors.slack_user_id IS 'Slack user ID for integration';
COMMENT ON COLUMN realtors.territories IS 'Array of geographic regions covered';
COMMENT ON COLUMN realtors.status IS 'Account status: active, inactive, suspended, pending';
COMMENT ON COLUMN realtors.metadata IS 'Additional flexible data storage';
