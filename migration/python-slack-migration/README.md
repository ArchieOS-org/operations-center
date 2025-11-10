# Python + Slack Migration (Phase 2 - CURRENT)

Python port of the current TypeScript + Slack classification system.

**Use this version NOW** - it matches your existing Slack-based system.

---

## What This Is

This is a **direct Python port** of your TypeScript Slack agent:

**TypeScript (Current):**
```
Slack Message → Fastify → OpenAI Agent SDK → Classification
```

**Python (This Migration):**
```
Slack Message → Vercel Function → OpenAI API → Classification
```

### Key Points

- ✅ **Uses Slack** (same as current system)
- ✅ **Same classification logic** (ported from TypeScript)
- ✅ **Same schema** (Pydantic instead of Zod)
- ✅ **Stateless** (no conversation history yet)
- ✅ **Vercel ready** (10-second timeout)

---

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Set Environment Variables

```bash
export OPENAI_API_KEY="sk-..."
export SLACK_SIGNING_SECRET="..."
export SLACK_BYPASS_VERIFY="false"
```

### 3. Test Classifier Locally

```bash
python classifier.py
```

Expected output:
```json
{
  "schema_version": 1,
  "message_type": "STRAY",
  "task_key": "SALE_CLOSING_TASKS",
  "confidence": 0.9,
  ...
}
```

### 4. Test Slack Webhook Locally

```bash
python api/slack_events.py
```

In another terminal:
```bash
# Test URL verification
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d '{"type":"url_verification","challenge":"test123"}'

# Test message classification
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d '{"type":"event_callback","event":{"type":"message","text":"We got an offer on 123 Main St","user":"U123","channel":"C456"},"event_id":"Ev123"}'
```

---

## Deploy to Vercel

### 1. Install Vercel CLI

```bash
npm install -g vercel
```

### 2. Set Environment Variables

```bash
vercel env add OPENAI_API_KEY
vercel env add SLACK_SIGNING_SECRET
```

### 3. Deploy

```bash
vercel deploy --prod
```

### 4. Configure Slack

1. Go to Slack App Settings → Event Subscriptions
2. Enable Events
3. Request URL: `https://your-project.vercel.app/api/slack/events`
4. Subscribe to bot events:
   - `app_mention`
   - `message.channels`
   - `message.groups`

---

## File Structure

```
python-slack-migration/
├── README.md              # This file
├── .env.example           # Environment variables
├── .gitignore            # Python gitignore
├── requirements.txt       # Dependencies
├── vercel.json           # Vercel config
├── schema.py             # Pydantic models (ClassificationV1)
├── classifier.py         # OpenAI classifier with instructions
└── api/
    └── slack_events.py   # Slack webhook handler
```

---

## How It Works

### 1. Slack sends webhook
```json
{
  "type": "event_callback",
  "event": {
    "type": "message",
    "text": "We got an offer on 123 Main St by Friday",
    "user": "U123ABC",
    "channel": "C456DEF",
    "ts": "1699635600.123456"
  },
  "event_id": "Ev123"
}
```

### 2. Signature verification
```python
verify_slack_signature(signing_secret, timestamp, body, signature)
```

### 3. Classification
```python
classification = classify_message(message_text)
# Returns ClassificationV1 with message_type, task_key, etc.
```

### 4. Store result
```python
# TODO: Save to database
# For now, just logs to console
print(classification.model_dump_json(indent=2))
```

---

## Differences from TypeScript

| Aspect | TypeScript | Python |
|--------|-----------|--------|
| **Agent SDK** | OpenAI Agent SDK | Direct OpenAI API |
| **Schema** | Zod | Pydantic |
| **Framework** | Fastify | Vercel Functions |
| **Signature** | `slackVerify.ts` | `verify_slack_signature()` |
| **Routes** | Fastify routes | Serverless functions |

### Why No Agent SDK?

The OpenAI Agent SDK (TypeScript) gives us structured outputs, but we can get the same result with direct API + Pydantic:

```python
# Direct API call
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": message}],
    response_format={"type": "json_object"}  # Structured output
)

# Parse with Pydantic
classification = ClassificationV1.model_validate_json(response.content)
```

This is simpler and gives us more control.

---

## Next Steps

### Immediate (This Migration)
1. ✅ Test classifier locally
2. ✅ Test Slack webhook locally
3. ✅ Deploy to Vercel
4. ✅ Configure Slack webhook URL
5. ✅ Test with real Slack messages

### Future (Phase 3 - SMS)
- See `../python-sms-migration/` folder
- Adds Twilio SMS support
- Adds Supabase storage
- Adds Swift dashboard APIs

---

## Testing

### Test Classifier
```bash
python classifier.py
```

### Test Slack Webhook (URL Verification)
```bash
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d '{"type":"url_verification","challenge":"3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P"}'
```

### Test Slack Webhook (Message Event)
```bash
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d '{
    "type": "event_callback",
    "event": {
      "type": "message",
      "text": "We need to schedule closing for 123 Main St by Friday",
      "user": "U123ABC",
      "channel": "C456DEF",
      "ts": "1699635600.123456"
    },
    "event_id": "Ev123ABC"
  }'
```

---

## Troubleshooting

### Issue: "Invalid signature"
- Check `SLACK_SIGNING_SECRET` is correct
- For local testing, set `SLACK_BYPASS_VERIFY=true`

### Issue: "OpenAI returned empty response"
- Check `OPENAI_API_KEY` is set
- Check API quota/rate limits

### Issue: "Failed to parse OpenAI response"
- Check the raw response in logs
- OpenAI might be returning invalid JSON

---

## Production Considerations

### 1. Message Queue
Currently processes messages inline. For production:
- Send to SQS queue
- Process asynchronously
- Respond to Slack within 3 seconds

### 2. Database Storage
Currently just logs. For production:
- Save to DynamoDB or PostgreSQL
- Track classification results
- Enable analytics

### 3. Error Handling
- Retry failed classifications
- Alert on repeated failures
- Log to CloudWatch/Datadog

---

## Migration Checklist

- [ ] Install dependencies (`pip install -r requirements.txt`)
- [ ] Set environment variables
- [ ] Test classifier locally
- [ ] Test webhook locally
- [ ] Deploy to Vercel
- [ ] Configure Slack webhook URL
- [ ] Test with real Slack message
- [ ] Monitor logs for errors
- [ ] Add database storage (when ready)
- [ ] Add message queue (when ready)

---

## Support

- **TypeScript reference:** See `../typescript-original/`
- **SMS version (future):** See `../python-sms-migration/`
- **Main guide:** See `../README.md`
