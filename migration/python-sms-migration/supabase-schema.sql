-- Supabase Database Schema for SMS Bot
-- Run this in Supabase SQL Editor

-- Users table (phone number as primary identifier)
CREATE TABLE IF NOT EXISTS users (
    phone_number TEXT PRIMARY KEY,
    email TEXT,
    name TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations (one per user per agent type)
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL REFERENCES users(phone_number) ON DELETE CASCADE,
    agent_type TEXT DEFAULT 'classifier',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    UNIQUE(phone_number, agent_type)
);

-- Messages with full history and classification
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    twilio_sid TEXT,
    classification JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
    ON messages(conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_phone
    ON conversations(phone_number);

CREATE INDEX IF NOT EXISTS idx_conversations_last_message
    ON conversations(last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_twilio_sid
    ON messages(twilio_sid) WHERE twilio_sid IS NOT NULL;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- View for recent conversations (useful for Swift dashboard)
CREATE OR REPLACE VIEW recent_conversations AS
SELECT
    c.id as conversation_id,
    c.phone_number,
    c.agent_type,
    c.last_message_at,
    u.name as user_name,
    (
        SELECT content
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
    ) as last_message,
    (
        SELECT COUNT(*)
        FROM messages
        WHERE conversation_id = c.id
    ) as message_count
FROM conversations c
JOIN users u ON c.phone_number = u.phone_number
ORDER BY c.last_message_at DESC;

-- View for message classifications (useful for analytics)
CREATE OR REPLACE VIEW message_classifications AS
SELECT
    m.id,
    m.conversation_id,
    m.content,
    m.created_at,
    c.phone_number,
    m.classification->>'message_type' as message_type,
    m.classification->>'task_key' as task_key,
    m.classification->>'group_key' as group_key,
    (m.classification->>'confidence')::float as confidence,
    m.classification->'listing'->>'type' as listing_type,
    m.classification->'listing'->>'address' as listing_address
FROM messages m
JOIN conversations c ON m.conversation_id = c.id
WHERE m.classification IS NOT NULL
ORDER BY m.created_at DESC;

-- Grant permissions (if using RLS)
-- For now, disable RLS since we're using service key
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- Optional: Enable RLS and create policies if you want user-level isolation later
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY users_isolation ON users
--     FOR ALL
--     USING (phone_number = current_setting('app.current_user_phone', true));

-- Sample data for testing (optional)
-- INSERT INTO users (phone_number, name) VALUES ('+14155551234', 'Test User');
-- INSERT INTO conversations (phone_number, agent_type)
--     VALUES ('+14155551234', 'classifier')
--     ON CONFLICT (phone_number, agent_type) DO NOTHING;

-- Useful queries for monitoring

-- Get all conversations with recent activity
-- SELECT * FROM recent_conversations LIMIT 10;

-- Get all classifications by type
-- SELECT message_type, COUNT(*) as count
-- FROM message_classifications
-- GROUP BY message_type
-- ORDER BY count DESC;

-- Get average confidence by message type
-- SELECT message_type, AVG(confidence) as avg_confidence, COUNT(*) as count
-- FROM message_classifications
-- GROUP BY message_type
-- ORDER BY count DESC;

-- Get recent messages for a phone number
-- SELECT * FROM messages
-- WHERE conversation_id IN (
--     SELECT id FROM conversations WHERE phone_number = '+14155551234'
-- )
-- ORDER BY created_at DESC
-- LIMIT 20;
