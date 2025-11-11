-- Migration: Create task_notes table
-- Context7 Pattern: PostgreSQL table with indexes and constraints
-- Source: PostgreSQL best practices

-- Create task_notes table
CREATE TABLE IF NOT EXISTS task_notes (
    note_id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 5000),
    author_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_task_notes_task_id ON task_notes(task_id);
CREATE INDEX IF NOT EXISTS idx_task_notes_author ON task_notes(author_id);
CREATE INDEX IF NOT EXISTS idx_task_notes_created ON task_notes(created_at);

-- Add RLS (Row Level Security)
ALTER TABLE task_notes ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_task_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_notes_updated_at
    BEFORE UPDATE ON task_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_task_notes_updated_at();

-- Add comment
COMMENT ON TABLE task_notes IS 'Task notes for tracking task history and communications';
