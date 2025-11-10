# Supabase Setup Guide

This guide walks you through setting up Supabase for the Operations Center project.

---

## Prerequisites

- A Supabase account (sign up at [supabase.com](https://supabase.com))
- Access to your Vercel project settings

---

## Step 1: Create a Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **"New Project"**
3. Fill in project details:
   - **Name**: operations-center
   - **Database Password**: Generate a strong password (save this!)
   - **Region**: Choose closest to your users (e.g., `us-east-1`)
   - **Pricing Plan**: Start with Free tier
4. Click **"Create new project"** (takes ~2 minutes)

---

## Step 2: Get Your Supabase Credentials

Once your project is created:

1. Go to **Project Settings** (gear icon in sidebar)
2. Navigate to **API** section
3. Copy these values:

### Required Credentials:
```bash
# Project URL
SUPABASE_URL=https://<your-project-ref>.supabase.co

# API Keys (under "Project API keys")
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # Public key (safe for client)
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # Private key (server-only)
```

**Important:**
- Use `SUPABASE_SERVICE_KEY` for backend operations (full access)
- Never expose `SUPABASE_SERVICE_KEY` in client-side code

---

## Step 3: Create Database Schema

### Tables Needed

#### 1. Classifications Table
Stores message classification results from the LangChain agent.

```sql
CREATE TABLE classifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Event metadata
  event_id TEXT UNIQUE NOT NULL,
  user_id TEXT NOT NULL,
  channel_id TEXT NOT NULL,
  message_ts TEXT NOT NULL,

  -- Message content
  message TEXT NOT NULL,

  -- Classification result (JSONB for flexibility)
  classification JSONB NOT NULL,

  -- Extracted fields (for easy querying)
  message_type TEXT NOT NULL,
  task_key TEXT,
  group_key TEXT,
  assignee_hint TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  confidence NUMERIC(3,2),

  -- Indexes for common queries
  INDEX idx_event_id (event_id),
  INDEX idx_message_type (message_type),
  INDEX idx_created_at (created_at DESC)
);
```

#### 2. Audit Log Table (Optional but Recommended)
Tracks all actions for debugging and compliance.

```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  action TEXT NOT NULL,
  actor_id TEXT,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  metadata JSONB,

  INDEX idx_created_at (created_at DESC),
  INDEX idx_resource_type (resource_type)
);
```

### How to Run SQL

1. Go to **SQL Editor** in Supabase dashboard (left sidebar)
2. Click **"New Query"**
3. Paste the SQL above
4. Click **"Run"** or press `Cmd+Enter`

---

## Step 4: Set Row-Level Security (RLS)

Supabase enables RLS by default. For backend operations:

### Option A: Disable RLS for Backend (Simpler)
```sql
ALTER TABLE classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Allow service key full access
CREATE POLICY "Service key can do anything" ON classifications
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service key can do anything" ON audit_log
  USING (auth.jwt() ->> 'role' = 'service_role');
```

### Option B: Fine-Grained Policies (Production)
```sql
-- Read-only for authenticated users
CREATE POLICY "Authenticated users can read" ON classifications
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Full access for service role
CREATE POLICY "Service role has full access" ON classifications
  USING (auth.jwt() ->> 'role' = 'service_role');
```

---

## Step 5: Add Environment Variables to Vercel

### Via Vercel Dashboard:
1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Select your **operations-center** project
3. Go to **Settings** → **Environment Variables**
4. Add these variables:

```bash
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_KEY=<your-service-role-key>
```

**Environment Scope:**
- Check: Production, Preview, Development

### Via Vercel CLI:
```bash
vercel env add SUPABASE_URL production
# Paste: https://<your-project-ref>.supabase.co

vercel env add SUPABASE_KEY production
# Paste: <your-service-role-key>
```

---

## Step 6: Install Supabase Python Client

Add to `requirements.txt`:
```txt
supabase>=2.0.0
```

Then deploy or test locally:
```bash
pip install -r requirements.txt
```

---

## Step 7: Initialize Supabase Client in Code

Create `backend/database/supabase_client.py`:

```python
import os
from supabase import create_client, Client

def get_supabase_client() -> Client:
    """
    Get or create Supabase client instance

    Reads SUPABASE_URL and SUPABASE_KEY from environment variables.
    Uses service role key for full access to database.
    """
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_KEY')

    if not url or not key:
        raise ValueError(
            "Missing Supabase credentials. "
            "Set SUPABASE_URL and SUPABASE_KEY environment variables."
        )

    return create_client(url, key)

# Singleton instance (reuse across requests)
_supabase_client = None

def get_supabase() -> Client:
    """Get singleton Supabase client"""
    global _supabase_client
    if _supabase_client is None:
        _supabase_client = get_supabase_client()
    return _supabase_client
```

---

## Step 8: Store Classifications in Supabase

Update `api/slack/events.py` to save results:

```python
from backend.database.supabase_client import get_supabase

def _process_slack_event(self, event: dict, event_id: str):
    # ... existing code ...

    try:
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

        print(f"Saved classification: {result.data}")

    except Exception as e:
        print(f"Error: {e}")
```

---

## Step 9: Test Supabase Connection

Create a test script:

```python
# test_supabase.py
from backend.database.supabase_client import get_supabase

def test_connection():
    try:
        supabase = get_supabase()
        result = supabase.table('classifications').select('*').limit(1).execute()
        print(f"✅ Supabase connected! Found {len(result.data)} records")
    except Exception as e:
        print(f"❌ Supabase error: {e}")

if __name__ == "__main__":
    test_connection()
```

Run locally:
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_KEY="your-service-key"
python test_supabase.py
```

---

## Verification Checklist

- [ ] Supabase project created
- [ ] Database schema created (classifications, audit_log tables)
- [ ] RLS policies configured
- [ ] Environment variables added to Vercel
- [ ] `supabase` package added to requirements.txt
- [ ] Supabase client initialized in code
- [ ] Test connection successful

---

## Troubleshooting

### Error: "relation 'classifications' does not exist"
- Run the CREATE TABLE SQL in Step 3

### Error: "Invalid API key"
- Check that you're using the **service_role** key, not the anon key
- Verify the key is correctly set in Vercel environment variables

### Error: "Row-level security policy violation"
- Check RLS policies in Step 4
- Ensure you're using the service role key for backend operations

---

## Next Steps

1. ✅ Supabase is configured
2. → Continue with deployment (see `MIGRATION_PLAN.md`)
3. → Build macOS dashboard to view classifications

---

## Resources

- [Supabase Python Client Docs](https://supabase.com/docs/reference/python/introduction)
- [Supabase Dashboard](https://supabase.com/dashboard)
- [Row-Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
