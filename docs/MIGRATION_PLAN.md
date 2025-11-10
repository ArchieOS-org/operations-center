# Operations Center Migration Plan

Complete step-by-step guide to migrate from `archieos-backend-1` (TypeScript + DynamoDB) to `operations-center` (Python + LangChain + Supabase + Vercel).

---

## Migration Overview

### What's Changing:
| Component | Old (archieos-backend-1) | New (operations-center) |
|-----------|-------------------------|------------------------|
| **Language** | TypeScript | Python |
| **Agent Framework** | OpenAI Agent SDK | LangChain |
| **API Framework** | Fastify (Node.js server) | Vercel Serverless Functions |
| **Database** | DynamoDB (LocalStack) | Supabase (PostgreSQL) |
| **Hosting** | Self-hosted/AWS | Vercel |
| **Auth** | Custom (Google OAuth + JWT) | Supabase Auth (future) |

### What's Staying the Same:
✅ Slack App (same App ID, credentials)
✅ Classification logic (same prompts, schema)
✅ LLM provider (OpenAI, with option to switch)
✅ Message types, task keys, group keys

---

## Prerequisites

Before starting, ensure you have:

- [ ] Access to original project at `/Users/noahdeskin/archieos-backend-1`
- [ ] Vercel account connected to `operations-center` project
- [ ] Supabase account (sign up at [supabase.com](https://supabase.com))
- [ ] OpenAI API key (from [platform.openai.com](https://platform.openai.com))
- [ ] Slack App credentials (from old project `.env`)
- [ ] Vercel CLI installed: `npm install -g vercel`
- [ ] Python 3.11+ installed

---

## Phase 1: Setup & Configuration (30 minutes)

### Step 1.1: Set Up Supabase

Follow the detailed guide: `docs/SUPABASE_SETUP.md`

**Quick checklist:**
- [ ] Create Supabase project
- [ ] Run database schema SQL
- [ ] Configure RLS policies
- [ ] Save credentials (SUPABASE_URL, SUPABASE_KEY)

### Step 1.2: Gather Environment Variables

Follow the detailed guide: `docs/ENVIRONMENT_VARIABLES.md`

**From old project** (`/Users/noahdeskin/archieos-backend-1/.env`):
```bash
# Copy these values:
SLACK_APP_ID=A097F76UJQN
SLACK_SIGNING_SECRET=...
SLACK_BOT_TOKEN=xoxb-...
OPENAI_API_KEY=sk-proj-...
```

**New values** (from Supabase):
```bash
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_KEY=<your-service-role-key>
```

**Optional** (LangSmith for observability):
```bash
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=ls-...
LANGCHAIN_PROJECT=operations-center-prod
```

### Step 1.3: Add Environment Variables to Vercel

Via Vercel Dashboard:
1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Select **operations-center** project
3. Settings → Environment Variables
4. Add all variables from Step 1.2
5. Select: Production + Preview + Development

Or via CLI:
```bash
vercel env add OPENAI_API_KEY production
vercel env add SLACK_SIGNING_SECRET production
vercel env add SUPABASE_URL production
vercel env add SUPABASE_KEY production
```

---

## Phase 2: Organize Backend Code (15 minutes)

The backend code currently lives in `migration/python-langchain-optimal/`. We need to move it to the proper structure.

### Step 2.1: Create Proper Directory Structure

```bash
cd /Users/noahdeskin/conductor/operations-center/.conductor/bangalore

# Create backend structure
mkdir -p backend/database
mkdir -p backend/utils
mkdir -p api/slack

# Create __init__.py files
touch backend/__init__.py
touch backend/database/__init__.py
touch backend/utils/__init__.py
```

### Step 2.2: Move Core Files

```bash
# Move classifier and schema to backend
cp migration/python-langchain-optimal/classifier.py backend/
cp migration/python-langchain-optimal/schema.py backend/

# Move Slack webhook to api
cp migration/python-langchain-optimal/api/slack_events.py api/slack/events.py

# Move configuration files to root
cp migration/python-langchain-optimal/requirements.txt .
cp migration/python-langchain-optimal/vercel.json .
```

### Step 2.3: Create Supabase Client Module

Create `backend/database/supabase_client.py`:

```python
import os
from supabase import create_client, Client

_supabase_client = None

def get_supabase() -> Client:
    """Get or create Supabase client singleton"""
    global _supabase_client

    if _supabase_client is None:
        url = os.getenv('SUPABASE_URL')
        key = os.getenv('SUPABASE_KEY')

        if not url or not key:
            raise ValueError(
                "Missing Supabase credentials. "
                "Set SUPABASE_URL and SUPABASE_KEY environment variables."
            )

        _supabase_client = create_client(url, key)

    return _supabase_client
```

### Step 2.4: Extract Slack Verification Utility

Create `backend/utils/slack_verify.py`:

```python
import hmac
import hashlib
import time

def verify_slack_signature(
    signing_secret: str,
    timestamp: str,
    body: str,
    signature: str
) -> bool:
    """
    Verify Slack request signature using HMAC-SHA256

    Args:
        signing_secret: Slack app signing secret
        timestamp: X-Slack-Request-Timestamp header
        body: Raw request body string
        signature: X-Slack-Signature header

    Returns:
        bool: True if signature is valid
    """
    if not signing_secret or not signature or not timestamp:
        return False

    # Check timestamp (reject if > 5 minutes old)
    current_time = int(time.time())
    request_time = int(timestamp)
    if abs(current_time - request_time) > 300:
        return False

    # Calculate expected signature
    sig_basestring = f'v0:{timestamp}:{body}'
    expected_signature = 'v0=' + hmac.new(
        signing_secret.encode(),
        sig_basestring.encode(),
        hashlib.sha256
    ).hexdigest()

    # Constant-time comparison
    return hmac.compare_digest(expected_signature, signature)
```

### Step 2.5: Update Import Paths in `api/slack/events.py`

```python
# Update imports to use new structure
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from backend.classifier import classify_message
from backend.database.supabase_client import get_supabase
from backend.utils.slack_verify import verify_slack_signature
```

### Step 2.6: Update `requirements.txt`

```txt
# Core LangChain packages
langchain>=0.3.0
langchain-openai>=0.2.0
langchain-core>=0.3.0

# Pydantic for schema validation
pydantic>=2.6.0

# Supabase for database
supabase>=2.0.0

# Optional: LangSmith for observability
langsmith>=0.1.0
```

### Step 2.7: Update `vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "functions": {
    "api/**/*.py": {
      "runtime": "python3.11",
      "maxDuration": 10,
      "excludeFiles": "{tests/**,__tests__/**,**/*.test.py,**/test_*.py,fixtures/**,__fixtures__/**,testdata/**,migration/**}"
    }
  },
  "env": {
    "OPENAI_API_KEY": "@openai-api-key",
    "OPENAI_MODEL": "gpt-4o-mini",
    "SLACK_SIGNING_SECRET": "@slack-signing-secret",
    "SLACK_BOT_TOKEN": "@slack-bot-token",
    "SLACK_BYPASS_VERIFY": "false",
    "SUPABASE_URL": "@supabase-url",
    "SUPABASE_KEY": "@supabase-key",
    "LANGCHAIN_TRACING_V2": "true",
    "LANGCHAIN_API_KEY": "@langchain-api-key",
    "LANGCHAIN_PROJECT": "operations-center-prod"
  }
}
```

---

## Phase 3: Add Supabase Integration (20 minutes)

### Step 3.1: Update Slack Webhook to Save to Supabase

Edit `api/slack/events.py` and modify the `_process_slack_event` method:

```python
def _process_slack_event(self, event: dict, event_id: str):
    """Process Slack message event and save to Supabase"""
    message_text = event.get('text', '')
    user_id = event.get('user', '')
    channel_id = event.get('channel', '')
    ts = event.get('ts', '')

    if not message_text:
        return

    try:
        # Classify message using LangChain
        classification = classify_message(message_text, message_timestamp=ts)

        # Save to Supabase
        supabase = get_supabase()
        result = supabase.table('classifications').insert({
            'event_id': event_id,
            'user_id': user_id,
            'channel_id': channel_id,
            'message_ts': ts,
            'message': message_text,
            'classification': classification.model_dump(),
            'message_type': classification.message_type.value,
            'task_key': classification.task_key.value if classification.task_key else None,
            'group_key': classification.group_key.value if classification.group_key else None,
            'assignee_hint': classification.assignee_hint,
            'due_date': classification.due_date,
            'confidence': classification.confidence
        }).execute()

        print(f"✅ Saved classification: {result.data[0]['id']}")

        # Optional: Log to audit_log
        supabase.table('audit_log').insert({
            'action': 'classification_created',
            'actor_id': user_id,
            'resource_type': 'classification',
            'resource_id': result.data[0]['id'],
            'metadata': {
                'message_type': classification.message_type.value,
                'confidence': classification.confidence
            }
        }).execute()

    except Exception as e:
        print(f"❌ Error classifying message: {e}")
        import traceback
        traceback.print_exc()
```

### Step 3.2: Create Test Script

Create `backend/test_supabase.py`:

```python
#!/usr/bin/env python3
import os
from database.supabase_client import get_supabase

def test_connection():
    """Test Supabase connection and query"""
    try:
        supabase = get_supabase()

        # Test: Count classifications
        result = supabase.table('classifications').select('*', count='exact').execute()
        print(f"✅ Supabase connected!")
        print(f"   Found {result.count} classifications in database")

        # Test: Insert dummy record
        test_record = supabase.table('classifications').insert({
            'event_id': 'test-123',
            'user_id': 'U000000',
            'channel_id': 'C000000',
            'message_ts': '1234567890.000',
            'message': 'Test message',
            'classification': {},
            'message_type': 'IGNORE',
            'confidence': 1.0
        }).execute()

        print(f"✅ Test record inserted: {test_record.data[0]['id']}")

        # Clean up test record
        supabase.table('classifications').delete().eq('event_id', 'test-123').execute()
        print("✅ Test record cleaned up")

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # Load environment variables (for local testing)
    from dotenv import load_dotenv
    load_dotenv()

    test_connection()
```

---

## Phase 4: Deploy to Vercel (10 minutes)

### Step 4.1: Test Locally (Optional)

```bash
# Install dependencies
pip install -r requirements.txt

# Install python-dotenv for local testing
pip install python-dotenv

# Create .env file (copy from .env.example)
cp .env.example .env
# Fill in your values

# Test Supabase connection
python backend/test_supabase.py

# Test classifier
python backend/classifier.py
```

### Step 4.2: Commit Changes

```bash
git add .
git commit -m "feat: migrate to Python + LangChain + Supabase

- Move backend code from migration folder to proper structure
- Add Supabase integration for storing classifications
- Update Slack webhook to save to database
- Configure Vercel deployment"
```

### Step 4.3: Deploy to Vercel

```bash
# Deploy to production
vercel --prod

# Or let Vercel auto-deploy via Git push
git push origin main
```

### Step 4.4: Verify Deployment

1. Check Vercel deployment logs:
   - Go to [vercel.com/dashboard](https://vercel.com/dashboard)
   - Select **operations-center**
   - View latest deployment

2. Get your webhook URL:
   ```
   https://operations-center.vercel.app/api/slack/events
   ```

---

## Phase 5: Update Slack Configuration (5 minutes)

### Step 5.1: Update Slack Webhook URL

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Select your app (App ID: A097F76UJQN)
3. Go to **Event Subscriptions**
4. Enable Events
5. Update Request URL:
   ```
   https://operations-center.vercel.app/api/slack/events
   ```
6. Verify URL (should show "Verified ✓")

### Step 5.2: Subscribe to Events

Under **Subscribe to bot events**, ensure these are added:
- `app_mention`
- `message.channels`
- `message.groups`

Click **Save Changes**

---

## Phase 6: Testing & Verification (15 minutes)

### Step 6.1: Test with Real Slack Message

1. Open your Slack workspace
2. Go to a channel where the bot is installed
3. Send a test message:
   ```
   @ArchieBot We got an offer on 123 Main St! Closing by Friday.
   ```

### Step 6.2: Verify in Vercel Logs

1. Go to Vercel Dashboard → Deployments → Latest
2. Click **Runtime Logs**
3. Look for:
   ```
   ✅ Saved classification: <uuid>
   ```

### Step 6.3: Verify in Supabase

1. Go to Supabase Dashboard → SQL Editor
2. Run query:
   ```sql
   SELECT * FROM classifications
   ORDER BY created_at DESC
   LIMIT 5;
   ```
3. Verify your test message appears

### Step 6.4: Check LangSmith (if enabled)

1. Go to [smith.langchain.com](https://smith.langchain.com)
2. Open your project
3. View recent traces
4. Verify LLM calls are being logged

---

## Phase 7: Data Migration (Optional)

If you have existing data in DynamoDB from the old project:

### Step 7.1: Export Data from DynamoDB

```bash
# From old project directory
cd /Users/noahdeskin/archieos-backend-1

# Export classifications (if any)
aws dynamodb scan \
  --table-name <your-table-name> \
  --endpoint-url http://localhost:4566 \
  --region us-east-1 \
  > export.json
```

### Step 7.2: Import to Supabase

Create a migration script:

```python
import json
from backend.database.supabase_client import get_supabase

def migrate_data():
    with open('export.json', 'r') as f:
        data = json.load(f)

    supabase = get_supabase()

    for item in data['Items']:
        # Transform DynamoDB format to Supabase format
        record = {
            'event_id': item['eventId']['S'],
            'user_id': item.get('userId', {}).get('S', ''),
            'message': item.get('message', {}).get('S', ''),
            # ... map other fields
        }

        supabase.table('classifications').insert(record).execute()
        print(f"Migrated: {record['event_id']}")

if __name__ == "__main__":
    migrate_data()
```

**Note:** Only migrate if you have critical historical data. Otherwise, start fresh.

---

## Post-Migration Checklist

### Deployment:
- [ ] Backend code organized in proper structure
- [ ] Supabase project created and schema applied
- [ ] Environment variables set in Vercel
- [ ] Code committed and pushed to Git
- [ ] Deployed to Vercel (production)
- [ ] Deployment successful (no errors in logs)

### Configuration:
- [ ] Slack webhook URL updated
- [ ] Slack events subscribed (app_mention, message.channels, message.groups)
- [ ] Slack webhook verified (✓ in Slack dashboard)

### Testing:
- [ ] Sent test message in Slack
- [ ] Classification logged in Vercel
- [ ] Classification saved in Supabase
- [ ] LangSmith traces visible (if enabled)

### Cleanup:
- [ ] Old LocalStack/DynamoDB no longer needed
- [ ] Old Fastify server can be archived
- [ ] Document any differences for team

---

## Rollback Plan

If something goes wrong:

1. **Revert Slack webhook URL** to old service (if still running)
2. **Check Vercel logs** for errors
3. **Verify environment variables** are set correctly
4. **Check Supabase status** (supabase.com/status)
5. **Review recent commits** and revert if needed

Common issues:
- Missing environment variables → Add in Vercel dashboard
- Supabase connection errors → Check service role key
- Slack signature verification failed → Check signing secret

---

## Next Steps After Migration

### Immediate (Week 1):
1. ✅ Monitor Vercel logs for errors
2. ✅ Check Supabase usage (free tier: 500 MB, 2 GB bandwidth)
3. ✅ Set up alerts in Vercel (optional)
4. ✅ Review LangSmith traces for quality

### Short-term (Month 1):
1. Build macOS dashboard to view classifications
2. Add more sophisticated error handling
3. Implement message queue (if timeout issues occur)
4. Add user feedback mechanism

### Long-term (Quarter 1):
1. Add SMS support (see `migration/python-sms-migration/`)
2. Implement conversation history (stateful agent)
3. A/B test OpenAI vs Anthropic Claude
4. Add real-time WebSocket updates
5. Multi-tenant support

---

## Cost Estimates

### Monthly Operating Costs:

| Service | Tier | Cost |
|---------|------|------|
| **Vercel** | Hobby | Free (or $20/month Pro) |
| **Supabase** | Free | $0 (up to 500 MB, 2 GB bandwidth) |
| **OpenAI** | Pay-as-you-go | $10-50 (depends on usage) |
| **LangSmith** | Free | $0 (up to 5,000 traces/month) |
| **Total** | | **$10-70/month** |

**Notes:**
- Vercel Hobby is free for non-commercial use
- Supabase Pro ($25/month) recommended for production
- OpenAI costs scale with message volume

---

## Support & Resources

### Documentation:
- `docs/SUPABASE_SETUP.md` - Supabase configuration
- `docs/ENVIRONMENT_VARIABLES.md` - Environment variables reference
- `README.md` - Project overview

### External Resources:
- [Vercel Python Functions](https://vercel.com/docs/functions/runtimes/python)
- [Supabase Python Client](https://supabase.com/docs/reference/python/introduction)
- [LangChain Documentation](https://python.langchain.com)
- [Slack Events API](https://api.slack.com/events-api)

### Getting Help:
- Vercel Support: [vercel.com/support](https://vercel.com/support)
- Supabase Discord: [discord.supabase.com](https://discord.supabase.com)
- LangChain Discord: [discord.gg/langchain](https://discord.gg/langchain)

---

## Conclusion

This migration moves you from a self-hosted TypeScript service to a modern, serverless Python stack with:

✅ **Scalability:** Vercel auto-scales, no server management
✅ **Flexibility:** LangChain makes swapping LLM providers trivial
✅ **Observability:** LangSmith gives production insights
✅ **Reliability:** Supabase provides managed Postgres with backups
✅ **Cost-effective:** Pay only for what you use

**Total migration time:** ~2-3 hours (including testing)

Good luck! 🚀
