-- Migration: Create slack_messages table for Slack message tracking
-- Created: 2025-11-11
-- Description: Tracks Slack messages with classification data and linkage to created tasks/listings

CREATE TABLE IF NOT EXISTS slack_messages (
    message_id TEXT PRIMARY KEY,
    slack_user_id TEXT NOT NULL,
    slack_channel_id TEXT NOT NULL,
    slack_ts TEXT NOT NULL UNIQUE,
    slack_thread_ts TEXT,
    message_text TEXT NOT NULL,

    -- Classification results
    classification JSONB NOT NULL,
    message_type TEXT NOT NULL,
    task_key TEXT,
    group_key TEXT,
    confidence NUMERIC(5, 4) CHECK (confidence >= 0 AND confidence <= 1),

    -- Created entity references
    created_listing_id TEXT,
    created_task_id TEXT,
    created_task_type TEXT CHECK (created_task_type IN ('listing_task', 'stray_task')),

    -- Timestamps
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,

    -- Processing status
    processing_status TEXT NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processed', 'failed', 'skipped')),
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Foreign key constraints (optional - may reference external tables)
    CONSTRAINT fk_slack_messages_listing FOREIGN KEY (created_listing_id)
        REFERENCES listings(listing_id) ON DELETE SET NULL
    -- Note: created_task_id can reference either listing_tasks or stray_tasks, so no FK constraint
);

-- Indexes for efficient querying
CREATE INDEX idx_slack_messages_slack_user ON slack_messages(slack_user_id, received_at DESC);
CREATE INDEX idx_slack_messages_channel ON slack_messages(slack_channel_id, received_at DESC);
CREATE INDEX idx_slack_messages_ts ON slack_messages(slack_ts);
CREATE INDEX idx_slack_messages_thread ON slack_messages(slack_thread_ts) WHERE slack_thread_ts IS NOT NULL;
CREATE INDEX idx_slack_messages_message_type ON slack_messages(message_type);
CREATE INDEX idx_slack_messages_task_key ON slack_messages(task_key) WHERE task_key IS NOT NULL;
CREATE INDEX idx_slack_messages_status ON slack_messages(processing_status, received_at DESC);
CREATE INDEX idx_slack_messages_created_listing ON slack_messages(created_listing_id) WHERE created_listing_id IS NOT NULL;
CREATE INDEX idx_slack_messages_created_task ON slack_messages(created_task_id, created_task_type) WHERE created_task_id IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE slack_messages ENABLE ROW LEVEL SECURITY;

-- Comments for documentation
COMMENT ON TABLE slack_messages IS 'Slack message history with classification and task creation tracking';
COMMENT ON COLUMN slack_messages.message_id IS 'Unique identifier (ULID format)';
COMMENT ON COLUMN slack_messages.slack_ts IS 'Slack message timestamp (unique identifier from Slack)';
COMMENT ON COLUMN slack_messages.slack_thread_ts IS 'Thread timestamp if message is in a thread';
COMMENT ON COLUMN slack_messages.classification IS 'Full classification result from LangChain classifier (JSON)';
COMMENT ON COLUMN slack_messages.message_type IS 'Classified message type (e.g., new_listing, task_request)';
COMMENT ON COLUMN slack_messages.task_key IS 'Task key from TaskKey enum if applicable';
COMMENT ON COLUMN slack_messages.group_key IS 'Group key for task categorization';
COMMENT ON COLUMN slack_messages.confidence IS 'Classification confidence score (0-1)';
COMMENT ON COLUMN slack_messages.created_listing_id IS 'Listing created from this message (if any)';
COMMENT ON COLUMN slack_messages.created_task_id IS 'Task ID created from this message (if any)';
COMMENT ON COLUMN slack_messages.created_task_type IS 'Type of task created: listing_task or stray_task';
COMMENT ON COLUMN slack_messages.processing_status IS 'Processing state: pending, processed, failed, skipped';
