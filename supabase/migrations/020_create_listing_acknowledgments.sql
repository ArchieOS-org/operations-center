-- Migration: Create listing_acknowledgments junction table
-- Tracks per-user (staff) acknowledgment of listings
-- Required before listing appears in user's views

CREATE TABLE listing_acknowledgments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    listing_id TEXT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    staff_id TEXT NOT NULL REFERENCES staff(staff_id) ON DELETE CASCADE,
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_from TEXT CHECK (acknowledged_from IN ('mobile', 'web', 'notification')),

    -- Ensure one acknowledgment per staff per listing
    UNIQUE(listing_id, staff_id)
);

-- Indexes for performance
CREATE INDEX idx_listing_acks_staff ON listing_acknowledgments(staff_id);
CREATE INDEX idx_listing_acks_listing ON listing_acknowledgments(listing_id);
CREATE INDEX idx_listing_acks_timestamp ON listing_acknowledgments(acknowledged_at);

-- Row Level Security
ALTER TABLE listing_acknowledgments ENABLE ROW LEVEL SECURITY;

-- Add helpful comment
COMMENT ON TABLE listing_acknowledgments IS
'Per-user acknowledgment tracking for listings. Required before listing appears in user views (outside Inbox). Implements the Claimed vs Unclaimed state model.';

COMMENT ON COLUMN listing_acknowledgments.acknowledged_from IS
'Source of acknowledgment: mobile (iOS app), web (web app), or notification (push notification action).';
