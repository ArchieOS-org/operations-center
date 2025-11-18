-- Migration: Add RLS policies for listing_notes table
-- Purpose: Enable proper access control for notes - all authenticated users can read,
--          authenticated users can create notes with their user ID,
--          users can only update/delete their own notes

-- RLS is already enabled from migration 003, we just need to add policies

-- SELECT: All authenticated users can read all notes
CREATE POLICY "Authenticated users can read all notes"
ON listing_notes
FOR SELECT
TO authenticated
USING (true);

-- INSERT: Authenticated users can create notes
-- Note: created_by will be set by the application using auth.uid()
CREATE POLICY "Authenticated users can create notes"
ON listing_notes
FOR INSERT
TO authenticated
WITH CHECK (true);

-- UPDATE: Users can only update their own notes
CREATE POLICY "Users can update their own notes"
ON listing_notes
FOR UPDATE
TO authenticated
USING (created_by = (SELECT auth.uid()::text))
WITH CHECK (created_by = (SELECT auth.uid()::text));

-- DELETE: Users can only delete their own notes
CREATE POLICY "Users can delete their own notes"
ON listing_notes
FOR DELETE
TO authenticated
USING (created_by = (SELECT auth.uid()::text));

COMMENT ON POLICY "Authenticated users can read all notes" ON listing_notes IS
  'All authenticated users can view all notes on all listings';
COMMENT ON POLICY "Authenticated users can create notes" ON listing_notes IS
  'Authenticated users can create notes - created_by is set by application';
COMMENT ON POLICY "Users can update their own notes" ON listing_notes IS
  'Users can only modify notes they created';
COMMENT ON POLICY "Users can delete their own notes" ON listing_notes IS
  'Users can only delete notes they created';
