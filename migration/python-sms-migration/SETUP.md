# Python Migration Setup Guide

Quick start guide for running the Python migration locally and deploying to Vercel.

## Prerequisites

- Python 3.11+
- OpenAI API key
- Supabase account + project
- Twilio account (for SMS)
- Vercel CLI (for deployment)

## Local Development Setup

### 1. Install Dependencies

```bash
cd python-migration
pip install -r requirements.txt
```

### 2. Set Environment Variables

Create a `.env` file:

```bash
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=eyJ...

# Twilio (for SMS)
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=xxx
TWILIO_PHONE_NUMBER=+1...
```

### 3. Setup Supabase Database

Run this SQL in Supabase SQL editor:

```sql
-- Users table
CREATE TABLE users (
    phone_number TEXT PRIMARY KEY,
    email TEXT,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL REFERENCES users(phone_number) ON DELETE CASCADE,
    agent_type TEXT DEFAULT 'classifier',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(phone_number, agent_type)
);

-- Messages with classification
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    twilio_sid TEXT,
    classification JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_conversations_phone ON conversations(phone_number);
```

### 4. Test the Classifier

```bash
python classifier.py
```

Expected output:
```json
{
  "schema_version": 1,
  "message_type": "STRAY",
  "task_key": "SALE_CLOSING_TASKS",
  "group_key": null,
  ...
}
```

### 5. Test the Webhook Locally

```bash
# Start local server
python api/sms/webhook.py

# In another terminal, send test request
curl -X POST http://localhost:8000 \
  -d 'From=+14155551234' \
  -d 'Body=We got an offer on 123 Main St!' \
  -d 'MessageSid=SM123'
```

Expected response:
```json
{
  "success": true,
  "message": "Message classified and saved",
  "classification": {
    "message_type": "STRAY",
    "confidence": 0.9
  }
}
```

## Deploy to Vercel

### 1. Install Vercel CLI

```bash
npm install -g vercel
```

### 2. Login to Vercel

```bash
vercel login
```

### 3. Set Environment Variables

```bash
vercel env add OPENAI_API_KEY
vercel env add SUPABASE_URL
vercel env add SUPABASE_SERVICE_KEY
vercel env add TWILIO_AUTH_TOKEN
vercel env add TWILIO_ACCOUNT_SID
```

### 4. Deploy

```bash
vercel deploy --prod
```

### 5. Get Your Webhook URL

Vercel will output:
```
https://your-project.vercel.app
```

Your webhook URL is:
```
https://your-project.vercel.app/api/sms/webhook
```

### 6. Configure Twilio

1. Go to Twilio Console → Phone Numbers → Your Number
2. Under "Messaging", set:
   - **A message comes in**: Webhook
   - **URL**: `https://your-project.vercel.app/api/sms/webhook`
   - **HTTP Method**: POST

## Testing in Production

Send an SMS to your Twilio number:

```
We need to schedule a showing for 123 Main St by Friday
```

Check your Supabase database:

```sql
SELECT * FROM messages ORDER BY created_at DESC LIMIT 1;
```

You should see:
- The message content
- The classification JSON
- Timestamp

## Monitoring

### View Logs

```bash
vercel logs
```

### Check Supabase

Go to Supabase → Table Editor → `messages`

### Troubleshooting

**Issue: "OpenAI returned empty response"**
- Check OPENAI_API_KEY is set correctly
- Check API quota/rate limits

**Issue: "Failed to parse OpenAI response"**
- Check the raw response in logs
- OpenAI might be returning invalid JSON

**Issue: "Supabase error"**
- Check SUPABASE_URL and SUPABASE_SERVICE_KEY
- Verify tables exist
- Check RLS policies (should be disabled for service key)

**Issue: "Twilio signature verification failed"**
- Uncomment signature verification code in webhook.py
- Check TWILIO_AUTH_TOKEN is correct

## Next Steps

1. ✅ Deploy webhook to Vercel
2. ✅ Test with SMS messages
3. 🔲 Build Swift macOS dashboard to view conversations
4. 🔲 Add real-time updates (WebSocket or polling)
5. 🔲 Add admin features (search, filters)
6. 🔲 Later: Add conversational agent (if needed)

## Performance Tips

- Cold start: ~1 second (acceptable for SMS)
- OpenAI API: ~800ms average
- Supabase queries: ~50ms average
- Total: ~1-2 seconds end-to-end ✅

## Cost Estimates

**Vercel:**
- Free tier: 100GB-hrs/month
- Pro tier: $20/month (if needed)

**OpenAI:**
- gpt-4o-mini: ~$0.0003 per request
- 1000 messages/day = ~$9/month

**Supabase:**
- Free tier: 500MB database
- Pro tier: $25/month (if needed)

**Twilio:**
- SMS: $0.0079 per message (US)
- 1000 messages/day = ~$240/month

**Total: ~$260-$280/month** (mostly Twilio SMS costs)

## Files Overview

```
python-migration/
├── schema.py              # Pydantic models (ClassificationV1)
├── classifier.py          # OpenAI classification logic
├── api/
│   └── sms/
│       └── webhook.py     # Vercel function (SMS webhook)
├── requirements.txt       # Python dependencies
├── vercel.json           # Vercel deployment config
├── SETUP.md              # This file
└── README.md             # Migration guide (in parent dir)
```

## Getting Help

- **OpenAI API**: https://platform.openai.com/docs
- **Pydantic**: https://docs.pydantic.dev
- **Supabase**: https://supabase.com/docs
- **Vercel Python**: https://vercel.com/docs/functions/runtimes/python
- **Twilio**: https://www.twilio.com/docs/sms
