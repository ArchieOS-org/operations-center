# Agent System Migration Guide

This directory contains the current TypeScript agent system and **three Python migration options**.

## Overview

The current system is a **stateless message classifier** that:
1. Receives Slack messages via webhook
2. Classifies them using OpenAI's GPT-4o-mini
3. Extracts structured data (listing type, addresses, tasks, due dates)
4. Returns a JSON classification result

**Key Insight:** This is NOT a conversational agent. It's a single-turn classifier with no conversation history.

## Directory Structure

```
migration/
├── README.md                          # This file
│
├── typescript-original/               # Current TypeScript implementation
│   ├── slackAgent.ts                 # OpenAI Agent SDK configuration
│   ├── openaiClient.ts               # OpenAI client setup
│   ├── llmClassifier.ts              # Zod schema + classification logic
│   ├── slack-routes.ts               # Fastify webhook handler
│   └── ...
│
├── python-slack-migration/            # ✅ Phase 2: Python + Slack (USE NOW)
│   ├── README.md                     # Slack-specific guide
│   ├── schema.py                     # Pydantic models
│   ├── classifier.py                 # Direct OpenAI API
│   └── api/slack_events.py           # Slack webhook handler
│
├── python-langchain-optimal/          # ✅ OPTIMAL: Python + LangChain
│   ├── README.md                     # Complete benefits guide
│   ├── schema.py                     # Pydantic models
│   ├── classifier.py                 # LangChain agent with structured output
│   └── api/slack_events.py           # Slack webhook handler
│
└── python-sms-migration/              # Phase 3: Python + SMS (FUTURE)
    ├── SETUP.md                      # SMS setup guide
    ├── schema.py                     # Pydantic models
    ├── classifier.py                 # Direct OpenAI API
    ├── api/sms/webhook.py            # Twilio webhook handler
    ├── api/conversations.py          # Dashboard APIs
    ├── supabase-schema.sql           # Database schema
    └── ...
```

## Which Python Implementation Should You Use?

### 🏆 **python-langchain-optimal/** (RECOMMENDED FOR PRODUCTION)

**Best for:** Production deployments, enterprises, future-proofing

**Advantages:**
- ✅ Automatic Pydantic validation (no manual JSON parsing)
- ✅ Built-in error handling and retries
- ✅ Provider agnostic (swap OpenAI ↔ Anthropic in 2 lines)
- ✅ LangSmith tracing for debugging production issues
- ✅ Middleware support for future enhancements
- ✅ Enterprise-grade by default

**Use when:**
- You want production-ready code out of the box
- You may switch LLM providers later (OpenAI → Anthropic)
- You want built-in observability (LangSmith)
- You want standardized patterns

**See:** `python-langchain-optimal/README.md` for detailed benefits

---

### 📦 **python-slack-migration/** (SIMPLEST MIGRATION)

**Best for:** Quick migration, minimal dependencies, learning

**Advantages:**
- ✅ Direct port of TypeScript implementation
- ✅ Minimal dependencies (openai, pydantic only)
- ✅ Easiest to understand and debug
- ✅ Same logic as current TypeScript system

**Use when:**
- You want the simplest possible migration
- You're comfortable with manual error handling
- You don't need to swap LLM providers
- You want minimal abstraction

**See:** `python-slack-migration/README.md` for setup

---

### 🚀 **python-sms-migration/** (FUTURE: SMS + DASHBOARD)

**Best for:** Future SMS support with supervisor dashboard

**Advantages:**
- ✅ Twilio SMS webhook integration
- ✅ Supabase storage for conversation history
- ✅ Dashboard APIs for Swift supervisor app
- ✅ Real-time message visibility

**Use when:**
- You're ready to add SMS support
- You need a supervisor dashboard
- You want conversation history storage

**See:** `python-sms-migration/SETUP.md` for full guide

---

## Current Architecture (TypeScript)

### Flow
```
Slack Message → Webhook → Verify Signature → Dedupe → OpenAI Agent SDK → Classify → Return JSON
```

### Key Components

#### 1. **slackAgent.ts** - Agent Configuration
- Uses OpenAI Agent SDK (`@openai/agents`)
- Model: `gpt-4o-mini`
- Instructions: ~100 lines of classification rules
- Output: Structured JSON via Zod schema

#### 2. **llmClassifier.ts** - Schema Definition
Defines the classification output structure:

```typescript
interface ClassificationV1 {
  schema_version: 1;
  message_type: 'GROUP' | 'STRAY' | 'INFO_REQUEST' | 'IGNORE';
  task_key: string | null;
  group_key: 'SALE_LISTING' | 'LEASE_LISTING' | ... | null;
  listing: { type: 'LEASE' | 'SALE' | null; address: string | null };
  assignee_hint: string | null;
  due_date: string | null;
  task_title: string | null;
  confidence: number; // 0..1
  explanations: string[] | null;
}
```

#### 3. **slack-routes.ts** - Webhook Handler
- Fastify route: `POST /slack/events`
- Signature verification (HMAC-SHA256)
- Deduplication (900s TTL)
- Responds to Slack challenge requests

---

## Comparison Matrix

| Feature | TypeScript (Current) | Python (Direct API) | **Python (LangChain)** | Python (SMS) |
|---------|---------------------|---------------------|----------------------|--------------|
| **Platform** | Slack | Slack | Slack | SMS (Twilio) |
| **Agent SDK** | OpenAI Agent SDK | Direct OpenAI API | LangChain | Direct OpenAI API |
| **Schema** | Zod | Pydantic | Pydantic (validated) | Pydantic |
| **Validation** | Automatic | Manual | ✅ Automatic | Manual |
| **Error Handling** | Built-in | Custom | ✅ Built-in | Custom |
| **LLM Provider** | OpenAI only | OpenAI only | ✅ Any provider | OpenAI only |
| **Observability** | Custom | Custom | ✅ LangSmith | Custom |
| **Storage** | None | None | None | ✅ Supabase |
| **Dashboard APIs** | No | No | No | ✅ Yes |
| **Hosting** | AWS | Vercel | Vercel | Vercel |
| **Dependencies** | Medium | ✅ Minimal | Medium | High |
| **Production Ready** | Yes | Basic | ✅ Enterprise | Yes |

---

## Migration Paths

### Path 1: Simplest (Slack → Python Direct API)
```
Current TypeScript/Slack → python-slack-migration/
```
**Timeline:** 1-2 days
**Effort:** Low
**Best for:** Quick migration, minimal changes

---

### Path 2: Optimal (Slack → Python LangChain)
```
Current TypeScript/Slack → python-langchain-optimal/
```
**Timeline:** 1-2 days
**Effort:** Low (same as Path 1)
**Best for:** Production deployments, future-proofing

---

### Path 3: Future (Slack → SMS + Dashboard)
```
Current TypeScript/Slack → python-sms-migration/ + Swift Dashboard
```
**Timeline:** 1-2 weeks
**Effort:** High
**Best for:** Adding SMS support and supervisor dashboard

---

## Quick Start (LangChain - RECOMMENDED)

### 1. Navigate to optimal implementation
```bash
cd migration/python-langchain-optimal/
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Set environment variables
```bash
export OPENAI_API_KEY="sk-..."
export SLACK_SIGNING_SECRET="..."

# Optional: Enable LangSmith tracing
export LANGCHAIN_TRACING_V2="true"
export LANGCHAIN_API_KEY="ls-..."
```

### 4. Test locally
```bash
python classifier.py  # Test classifier
python api/slack_events.py  # Test webhook
```

### 5. Deploy to Vercel
```bash
vercel deploy --prod
```

**See `python-langchain-optimal/README.md` for detailed setup.**

---

## Key Design Decisions

### Why Multiple Python Implementations?

1. **python-slack-migration/** - For those who want minimal changes from TypeScript
2. **python-langchain-optimal/** - For production deployments (RECOMMENDED)
3. **python-sms-migration/** - For future SMS support

You can choose based on your needs:
- **Minimal dependencies?** → Direct API
- **Production-ready?** → LangChain
- **SMS + Dashboard?** → SMS migration

### Why LangChain is "Optimal"

From Context7 research on LangChain best practices:

**Direct OpenAI API** (manual):
```python
response = client.chat.completions.create(...)
json_text = response.choices[0].message.content
classification = ClassificationV1.model_validate_json(json_text)  # Can fail
```

**LangChain** (automatic):
```python
result = agent.invoke({"messages": [...]})
classification = result["structured_response"]  # Guaranteed valid
```

Benefits:
- Automatic Pydantic validation
- Built-in retries on validation errors
- Easy to swap providers (OpenAI → Anthropic → etc.)
- LangSmith tracing out-of-the-box
- Middleware for custom logic

### Why Keep TypeScript?

The `typescript-original/` directory preserves:
- The exact classification instructions
- The working Zod schema
- The Slack signature verification logic
- The deduplication logic

This ensures you can always reference the working implementation.

---

## What Stays the Same (All Python Implementations)

✅ **Classification logic** (same instructions from TypeScript)
✅ **Schema structure** (same JSON output, just Pydantic instead of Zod)
✅ **Stateless design** (no conversation history)
✅ **Model** (gpt-4o-mini)
✅ **Single-turn** (one message → one classification)

---

## What Changes

| Aspect | TypeScript | Python (All) |
|--------|-----------|-------------|
| **Language** | TypeScript | Python |
| **Schema** | Zod | Pydantic |
| **Framework** | Fastify | Vercel Functions (http.server) |
| **Hosting** | AWS | Vercel Serverless |
| **Agent SDK** | OpenAI Agent SDK | Direct API or LangChain |

---

## Testing Your Migration

Each Python implementation has its own testing guide:

- **python-slack-migration/README.md** - Test direct API implementation
- **python-langchain-optimal/README.md** - Test LangChain implementation
- **python-sms-migration/SETUP.md** - Test SMS + Supabase implementation

General test approach:
1. Test schema parsing (Pydantic validation)
2. Test classifier (OpenAI API calls)
3. Test webhook locally (curl commands)
4. Test on Vercel (deploy and test live)

---

## What NOT to Change

❌ Don't change the classification logic (instructions)
❌ Don't change the schema structure
❌ Don't make it conversational yet (keep stateless)
❌ Don't add complex features (keep it simple)

---

## What TO Change (Based on Your Path)

### Path 1 & 2 (Slack → Python)
✅ Port to Python
✅ Use Pydantic instead of Zod
✅ Deploy to Vercel instead of AWS

### Path 3 (SMS + Dashboard)
✅ All above, plus:
✅ Add Supabase storage
✅ Switch from Slack to Twilio webhooks
✅ Add dashboard APIs for Swift app

---

## Recommendations

### For Production (Now)
**Use `python-langchain-optimal/`**

Reasons:
- Production-ready out of the box
- Built-in error handling and retries
- Easy to swap LLM providers later
- LangSmith observability
- Best practices from Context7

### For Learning / Experimentation
**Use `python-slack-migration/`**

Reasons:
- Minimal dependencies
- Easiest to understand
- Direct port of TypeScript logic
- Good for learning Python

### For Future SMS Support
**Wait until ready, then use `python-sms-migration/`**

Reasons:
- Not needed yet (current system uses Slack)
- Requires Supabase setup
- Requires Swift dashboard development

---

## Next Steps

1. **Choose your implementation** (LangChain recommended)
2. **Read the README** in that folder
3. **Test locally** with provided examples
4. **Deploy to Vercel**
5. **Configure Slack** webhook URL
6. **Test with real messages**
7. **Monitor with LangSmith** (if using LangChain)

---

## Questions?

Refer to:
- `typescript-original/` - Original working code
- `python-langchain-optimal/README.md` - Detailed LangChain benefits
- `python-slack-migration/README.md` - Simple migration guide
- `python-sms-migration/SETUP.md` - Future SMS guide
- OpenAI docs: https://platform.openai.com/docs
- LangChain docs: https://python.langchain.com
- Pydantic docs: https://docs.pydantic.dev
- Vercel Python docs: https://vercel.com/docs/functions/runtimes/python

---

**Remember:** You're migrating a simple classifier, not building a complex conversational agent. Choose the implementation that matches your needs and keep it simple!
