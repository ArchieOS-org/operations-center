-- Migration 015: Enable public read access for all tables
-- This allows the anon key to read data from all tables
-- In production, you'll want more restrictive policies based on auth

-- ============================================================
-- Listing Tasks - Public Read Access
-- ============================================================

CREATE POLICY "Public can read listing tasks"
ON listing_tasks
FOR SELECT
TO anon
USING (deleted_at IS NULL);

-- ============================================================
-- Stray Tasks - Public Read Access
-- ============================================================

CREATE POLICY "Public can read stray tasks"
ON stray_tasks
FOR SELECT
TO anon
USING (deleted_at IS NULL);

-- ============================================================
-- Staff - Public Read Access
-- ============================================================

CREATE POLICY "Public can read staff"
ON staff
FOR SELECT
TO anon
USING (deleted_at IS NULL);

-- ============================================================
-- Realtors - Public Read Access
-- ============================================================

CREATE POLICY "Public can read realtors"
ON realtors
FOR SELECT
TO anon
USING (deleted_at IS NULL);

-- ============================================================
-- Listings - Public Read Access
-- ============================================================

CREATE POLICY "Public can read listings"
ON listings
FOR SELECT
TO anon
USING (deleted_at IS NULL);

-- ============================================================
-- Slack Messages - Public Read Access
-- ============================================================

CREATE POLICY "Public can read slack messages"
ON slack_messages
FOR SELECT
TO anon
USING (deleted_at IS NULL);

-- Comments
COMMENT ON POLICY "Public can read listing tasks" ON listing_tasks IS 'Allow anonymous read access to non-deleted listing tasks';
COMMENT ON POLICY "Public can read stray tasks" ON stray_tasks IS 'Allow anonymous read access to non-deleted stray tasks';
COMMENT ON POLICY "Public can read staff" ON staff IS 'Allow anonymous read access to active staff';
COMMENT ON POLICY "Public can read realtors" ON realtors IS 'Allow anonymous read access to active realtors';
COMMENT ON POLICY "Public can read listings" ON listings IS 'Allow anonymous read access to non-deleted listings';
COMMENT ON POLICY "Public can read slack messages" ON slack_messages IS 'Allow anonymous read access to non-deleted slack messages';
