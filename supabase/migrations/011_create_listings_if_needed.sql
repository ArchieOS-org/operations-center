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
