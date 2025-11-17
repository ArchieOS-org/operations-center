-- Migration: Create listing_acknowledgments junction table
-- Tracks per-user acknowledgment of listings
-- Required before listing appears in user's views

CREATE TABLE listing_acknowledgments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_from TEXT CHECK (acknowledged_from IN ('mobile', 'web', 'notification')),

    -- Ensure one acknowledgment per user per listing
    UNIQUE(listing_id, user_id)
);

-- Indexes for performance
CREATE INDEX idx_listing_acks_user ON listing_acknowledgments(user_id);
CREATE INDEX idx_listing_acks_listing ON listing_acknowledgments(listing_id);
CREATE INDEX idx_listing_acks_timestamp ON listing_acknowledgments(acknowledged_at);

-- Row Level Security
ALTER TABLE listing_acknowledgments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own acknowledgments
CREATE POLICY "Users can view their own acknowledgments"
    ON listing_acknowledgments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can create their own acknowledgments
CREATE POLICY "Users can acknowledge listings"
    ON listing_acknowledgments
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own acknowledgments (if needed for re-acknowledgment)
CREATE POLICY "Users can remove their acknowledgments"
    ON listing_acknowledgments
    FOR DELETE
    USING (auth.uid() = user_id);

-- Add helpful comment
COMMENT ON TABLE listing_acknowledgments IS
'Per-user acknowledgment tracking for listings. Required before listing appears in user views (outside Inbox). Implements the Claimed vs Unclaimed state model.';

COMMENT ON COLUMN listing_acknowledgments.acknowledged_from IS
'Source of acknowledgment: mobile (iOS app), web (web app), or notification (push notification action).';
