-- Migration 013: Create slack_messages table
-- No dependencies on other new tables

CREATE TABLE IF NOT EXISTS slack_messages (
    message_id TEXT PRIMARY KEY,
    slack_user_id TEXT NOT NULL,
    slack_ts TEXT NOT NULL UNIQUE,
    message_text TEXT NOT NULL,
    classification JSONB NOT NULL,
    created_listing_id TEXT,
    created_task_id TEXT,
    created_task_type TEXT CHECK (created_task_type IN ('listing_task', 'stray_task')),
    processing_status TEXT NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processed', 'failed', 'skipped')),
    error_message TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes for slack_messages
CREATE INDEX IF NOT EXISTS idx_slack_messages_user ON slack_messages(slack_user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_status ON slack_messages(processing_status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_ts ON slack_messages(slack_ts) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_created_listing ON slack_messages(created_listing_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_created_task ON slack_messages(created_task_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slack_messages_created_at ON slack_messages(created_at) WHERE deleted_at IS NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_slack_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_slack_messages_updated_at') THEN
        CREATE TRIGGER trigger_slack_messages_updated_at
            BEFORE UPDATE ON slack_messages
            FOR EACH ROW
            EXECUTE FUNCTION update_slack_messages_updated_at();
    END IF;
END $$;

COMMENT ON TABLE slack_messages IS 'Tracks Slack messages with classification and processing status';
