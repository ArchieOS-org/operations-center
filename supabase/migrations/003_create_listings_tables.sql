-- Migration: Create listings and related tables
-- Context7 Pattern: PostgreSQL tables with indexes, constraints, and RLS
-- Source: PostgreSQL best practices

-- ============================================================
-- LISTINGS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS listings (
    listing_id TEXT PRIMARY KEY,
    address_string TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('new', 'in_progress', 'completed')) DEFAULT 'new',
    assignee TEXT,
    agent_id TEXT,
    due_date TIMESTAMPTZ,
    progress NUMERIC(5,2) CHECK (progress >= 0 AND progress <= 100),
    type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listings_assignee ON listings(assignee) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listings_agent ON listings(agent_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listings_created ON listings(created_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listings_due_date ON listings(due_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_listings_address ON listings(address_string) WHERE deleted_at IS NULL;

-- Add RLS (Row Level Security)
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_listings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER listings_updated_at
    BEFORE UPDATE ON listings
    FOR EACH ROW
    EXECUTE FUNCTION update_listings_updated_at();

-- ============================================================
-- LISTING DETAILS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS listing_details (
    id TEXT PRIMARY KEY,
    listing_id TEXT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    property_type TEXT,
    bedrooms INTEGER DEFAULT 0 CHECK (bedrooms >= 0),
    bathrooms NUMERIC(3,1) DEFAULT 0 CHECK (bathrooms >= 0),
    sqft INTEGER DEFAULT 0 CHECK (sqft >= 0),
    year_built INTEGER CHECK (year_built >= 0),
    list_price NUMERIC(12,2) DEFAULT 0 CHECK (list_price >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(listing_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_listing_details_listing ON listing_details(listing_id);
CREATE INDEX IF NOT EXISTS idx_listing_details_property_type ON listing_details(property_type);
CREATE INDEX IF NOT EXISTS idx_listing_details_price ON listing_details(list_price);

-- Add RLS
ALTER TABLE listing_details ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER listing_details_updated_at
    BEFORE UPDATE ON listing_details
    FOR EACH ROW
    EXECUTE FUNCTION update_listings_updated_at();

-- ============================================================
-- LISTING NOTES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS listing_notes (
    note_id TEXT PRIMARY KEY,
    listing_id TEXT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) >= 1),
    type TEXT NOT NULL DEFAULT 'general',
    created_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_listing_notes_listing ON listing_notes(listing_id);
CREATE INDEX IF NOT EXISTS idx_listing_notes_created ON listing_notes(created_at);
CREATE INDEX IF NOT EXISTS idx_listing_notes_type ON listing_notes(type);

-- Add RLS
ALTER TABLE listing_notes ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER listing_notes_updated_at
    BEFORE UPDATE ON listing_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_listings_updated_at();

-- ============================================================
-- AUDIT LOG TABLE (for listing history)
-- ============================================================
-- Drop existing audit_log if it exists with wrong schema
DROP TABLE IF EXISTS audit_log CASCADE;

CREATE TABLE audit_log (
    event_id TEXT PRIMARY KEY,
    entity_key TEXT NOT NULL,  -- Format: "listing#<listing_id>" or "task#<task_id>"
    action TEXT NOT NULL,
    performed_by TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changes JSONB,
    content TEXT
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log(entity_key);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_performed_by ON audit_log(performed_by);

-- Add RLS
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Add comments
COMMENT ON TABLE listings IS 'Real estate listings for the Operations Center';
COMMENT ON TABLE listing_details IS 'Property details for listings';
COMMENT ON TABLE listing_notes IS 'Notes attached to listings';
COMMENT ON TABLE audit_log IS 'Audit trail for all entity changes';
