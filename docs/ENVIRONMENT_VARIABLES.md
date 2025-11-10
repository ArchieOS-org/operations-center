# Environment Variables Reference

Complete guide to all environment variables needed for the Operations Center project.

---

## Overview

This project requires environment variables for:
- **LLM Provider** (OpenAI)
- **Slack Integration**
- **Supabase Database**
- **LangChain Observability** (optional but recommended)

---

## Required Environment Variables

### 1. OpenAI Configuration

```bash
# OpenAI API Key (required)
OPENAI_API_KEY=sk-proj-...

# Model selection (optional, defaults to gpt-4o-mini)
OPENAI_MODEL=gpt-4o-mini
```

**Where to get:**
1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Click "Create new secret key"
3. Copy the key (starts with `sk-proj-`)

**Cost Estimate:**
- gpt-4o-mini: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- Budget: ~$10-50/month for moderate usage

---

### 2. Slack Configuration

```bash
# Slack App ID
SLACK_APP_ID=A097F76UJQN

# Slack Signing Secret (required for webhook verification)
SLACK_SIGNING_SECRET=abc123...

# Slack Client Credentials (for OAuth, if needed)
SLACK_CLIENT_ID=2904359607012.9253244970838
SLACK_CLIENT_SECRET=...

# Slack Bot Token (for posting messages back to Slack)
SLACK_BOT_TOKEN=xoxb-...

# Slack Verification Token (legacy, not recommended)
SLACK_VERIFICATION_TOKEN=...

# Development: Bypass signature verification (DO NOT USE IN PRODUCTION)
SLACK_BYPASS_VERIFY=false
```

**Where to get:**
From your original project at `/Users/noahdeskin/archieos-backend-1/.env`

These values are specific to your existing Slack App (App ID: A097F76UJQN).

**Security Notes:**
- ⚠️ NEVER commit these values to git
- ⚠️ Set `SLACK_BYPASS_VERIFY=false` in production
- ✅ Use Vercel environment variables for secure storage

---

### 3. Supabase Configuration

```bash
# Supabase Project URL (required)
SUPABASE_URL=https://<your-project-ref>.supabase.co

# Supabase Service Role Key (required for backend)
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Where to get:**
1. Supabase Dashboard → Project Settings → API
2. Copy "Project URL"
3. Copy "service_role" key (not "anon" key!)

**Note:** Use `service_role` key for backend operations (full database access)

---

### 4. LangChain Observability (Optional but Recommended)

```bash
# Enable LangSmith tracing
LANGCHAIN_TRACING_V2=true

# LangSmith API Key
LANGCHAIN_API_KEY=ls-...

# LangSmith Project Name
LANGCHAIN_PROJECT=operations-center-prod
```

**Where to get:**
1. Go to [smith.langchain.com](https://smith.langchain.com)
2. Create account (free tier available)
3. Create a new project
4. Copy API key from Settings

**Benefits:**
- See every LLM call in production
- Track token usage and costs
- Debug classification errors
- Compare model performance

**Cost:** Free for up to 5,000 traces/month

---

## Setting Environment Variables

### Local Development

Create `.env` file (DO NOT COMMIT):

```bash
# .env
OPENAI_API_KEY=sk-proj-...
OPENAI_MODEL=gpt-4o-mini

SLACK_APP_ID=A097F76UJQN
SLACK_SIGNING_SECRET=...
SLACK_BOT_TOKEN=xoxb-...
SLACK_BYPASS_VERIFY=true  # Only for local testing!

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=eyJh...

LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=ls-...
LANGCHAIN_PROJECT=operations-center-dev
```

Then load in Python:
```python
from dotenv import load_dotenv
load_dotenv()
```

---

### Vercel Production

#### Option A: Vercel Dashboard

1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Select **operations-center** project
3. Go to **Settings** → **Environment Variables**
4. Add each variable:
   - Key: `OPENAI_API_KEY`
   - Value: `sk-proj-...`
   - Environments: Production, Preview, Development

#### Option B: Vercel CLI

```bash
# Add variables one by one
vercel env add OPENAI_API_KEY production
# Paste value when prompted

vercel env add SLACK_SIGNING_SECRET production
vercel env add SUPABASE_URL production
vercel env add SUPABASE_KEY production

# Optional: LangSmith
vercel env add LANGCHAIN_TRACING_V2 production
vercel env add LANGCHAIN_API_KEY production
vercel env add LANGCHAIN_PROJECT production
```

#### Option C: Vercel Secrets (for sensitive values)

```bash
# Store sensitive values as secrets
vercel secrets add openai-api-key sk-proj-...
vercel secrets add slack-signing-secret abc123...
vercel secrets add supabase-key eyJh...

# Reference in vercel.json
{
  "env": {
    "OPENAI_API_KEY": "@openai-api-key",
    "SLACK_SIGNING_SECRET": "@slack-signing-secret",
    "SUPABASE_KEY": "@supabase-key"
  }
}
```

---

## Environment Variables by File

### `vercel.json`
```json
{
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

### `.env.example` (template for developers)
```bash
# Copy this to .env and fill in your values
# DO NOT COMMIT .env to git!

# OpenAI
OPENAI_API_KEY=sk-proj-your-key-here
OPENAI_MODEL=gpt-4o-mini

# Slack
SLACK_APP_ID=A097F76UJQN
SLACK_SIGNING_SECRET=your-signing-secret
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_BYPASS_VERIFY=true

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key

# LangChain (optional)
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=ls-your-key
LANGCHAIN_PROJECT=operations-center-dev
```

---

## Migrating from Old Project

Your old project (`archieos-backend-1`) had these environment variables:

### To Keep (Same Values):
```bash
SLACK_APP_ID=A097F76UJQN
SLACK_SIGNING_SECRET=(copy from old .env)
SLACK_CLIENT_ID=2904359607012.9253244970838
SLACK_CLIENT_SECRET=(copy from old .env)
SLACK_BOT_TOKEN=(copy from old .env)
OPENAI_API_KEY=(copy from old .env)
```

### Not Needed (DynamoDB/LocalStack):
```bash
# Old project used DynamoDB - no longer needed
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
LOCALSTACK_ENDPOINT=http://localhost:4566
ENTITIES_TABLE=entities
LISTINGS_TABLE=listings
# ... etc
```

### Replaced by Supabase:
```bash
# New Supabase variables replace DynamoDB
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
```

---

## Security Best Practices

### DO:
✅ Use Vercel environment variables (encrypted at rest)
✅ Use different keys for dev/staging/production
✅ Rotate keys periodically
✅ Use secrets for sensitive values (`@secret-name`)
✅ Set `SLACK_BYPASS_VERIFY=false` in production

### DON'T:
❌ Commit `.env` files to git
❌ Hardcode secrets in code
❌ Share API keys in Slack/email
❌ Use production keys in development
❌ Expose `SUPABASE_KEY` (service role) to clients

---

## Verification Checklist

Before deploying, verify:

- [ ] All required variables are set in Vercel
- [ ] `SLACK_BYPASS_VERIFY=false` in production
- [ ] Using `service_role` key for Supabase (not `anon`)
- [ ] `.env` is in `.gitignore`
- [ ] `.env.example` is committed (without real values)
- [ ] LangSmith is configured (optional but recommended)

---

## Troubleshooting

### Error: "Missing environment variable"
- Check Vercel dashboard → Settings → Environment Variables
- Ensure variables are set for correct environment (Production/Preview/Development)
- Redeploy after adding variables

### Error: "Invalid Slack signature"
- Verify `SLACK_SIGNING_SECRET` matches your Slack App settings
- Check that `SLACK_BYPASS_VERIFY=false` in production
- Ensure webhook URL in Slack matches your Vercel deployment

### Error: "Supabase: Invalid API key"
- Use `service_role` key, not `anon` key
- Copy key from Supabase Dashboard → Settings → API
- Verify no extra spaces/newlines in key

---

## Next Steps

1. ✅ Set all environment variables in Vercel
2. → Continue with deployment (see `MIGRATION_PLAN.md`)
3. → Test with real Slack messages

---

## Resources

- [Vercel Environment Variables Docs](https://vercel.com/docs/projects/environment-variables)
- [Slack App Management](https://api.slack.com/apps)
- [OpenAI API Keys](https://platform.openai.com/api-keys)
- [Supabase Dashboard](https://supabase.com/dashboard)
- [LangSmith](https://smith.langchain.com)
