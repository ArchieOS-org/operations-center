-- Migration: Add created_by_name to listing_notes
-- Purpose: Store creator's display name for UI without complex joins

ALTER TABLE listing_notes
ADD COLUMN created_by_name TEXT;

COMMENT ON COLUMN listing_notes.created_by_name IS
  'Display name of the user who created this note - populated by application';
