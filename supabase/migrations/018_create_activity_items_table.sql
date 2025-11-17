-- Migration 018: Create activity_items table
-- Checklist items within activities (NOT subtasks - avoid task terminology)

-- ============================================================
-- ACTIVITY ITEMS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS activity_items (
    activity_item_id TEXT PRIMARY KEY,
    parent_activity_id TEXT NOT NULL,
    name TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Foreign key to activities table
    CONSTRAINT fk_activity_items_parent
        FOREIGN KEY (parent_activity_id)
        REFERENCES activities(task_id)
        ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

-- Index for fetching all items for an activity
CREATE INDEX IF NOT EXISTS idx_activity_items_parent
    ON activity_items(parent_activity_id);

-- Index for filtering incomplete items (most common query)
CREATE INDEX IF NOT EXISTS idx_activity_items_incomplete
    ON activity_items(parent_activity_id)
    WHERE is_completed = FALSE;

-- Index for ordering by creation date
CREATE INDEX IF NOT EXISTS idx_activity_items_created
    ON activity_items(created_at DESC);

-- Composite index for completion tracking queries
CREATE INDEX IF NOT EXISTS idx_activity_items_parent_completed
    ON activity_items(parent_activity_id, is_completed);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE activity_items ENABLE ROW LEVEL SECURITY;

-- Policy: Staff can view all activity items
CREATE POLICY "Staff can view activity items"
    ON activity_items FOR SELECT
    USING (true);

-- Policy: Staff can insert activity items
CREATE POLICY "Staff can create activity items"
    ON activity_items FOR INSERT
    WITH CHECK (true);

-- Policy: Staff can update activity items
CREATE POLICY "Staff can update activity items"
    ON activity_items FOR UPDATE
    USING (true);

-- Policy: Staff can delete activity items
CREATE POLICY "Staff can delete activity items"
    ON activity_items FOR DELETE
    USING (true);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE activity_items IS 'Checklist items within property-related activities - individual actionable steps';
COMMENT ON COLUMN activity_items.activity_item_id IS 'Unique identifier (ULID format)';
COMMENT ON COLUMN activity_items.parent_activity_id IS 'Reference to parent activity (task_id in activities table)';
COMMENT ON COLUMN activity_items.name IS 'Display text for the checklist item (e.g., "Book photographer", "Deep clean rooms")';
COMMENT ON COLUMN activity_items.is_completed IS 'Completion status - toggles when user taps checkbox in UI';
COMMENT ON COLUMN activity_items.completed_at IS 'Timestamp when item was marked complete (NULL if not completed)';
COMMENT ON COLUMN activity_items.created_at IS 'When this checklist item was created';
