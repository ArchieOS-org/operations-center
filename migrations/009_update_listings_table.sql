-- Migration: Update listings table to add realtor reference
-- Created: 2025-11-11
-- Description: Adds realtor_id foreign key and removes generic assignee/agent_id columns

-- Add realtor_id column
ALTER TABLE listings
ADD COLUMN IF NOT EXISTS realtor_id TEXT;

-- Add foreign key constraint
ALTER TABLE listings
ADD CONSTRAINT fk_listings_realtor
FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id) ON DELETE SET NULL;

-- Create index for realtor lookups
CREATE INDEX idx_listings_realtor ON listings(realtor_id) WHERE deleted_at IS NULL;

-- Optional: Drop old columns (can be done later after data migration)
-- Uncomment these lines once data is migrated and verified:
-- ALTER TABLE listings DROP COLUMN IF EXISTS assignee;
-- ALTER TABLE listings DROP COLUMN IF EXISTS agent_id;

-- Add comment
COMMENT ON COLUMN listings.realtor_id IS 'Reference to the realtor (agent) for this listing';
