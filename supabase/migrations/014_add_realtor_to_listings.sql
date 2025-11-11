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
