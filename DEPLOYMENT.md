# Vercel Deployment Architecture

## The Problem We Solved

Vercel was creating **12 serverless functions** because the old `vercel.json` pattern was:

```json
{
  "functions": {
    "api/**/*.py": { ... }
  }
}
```

This told Vercel: "Create a separate serverless function for EVERY Python file."

Result:
- `agents/classifier.py` → Function 1
- `agents/orchestrator.py` → Function 2
- `workflows/slack_intake.py` → Function 3
- ... and so on

**Hobby plan limit: 12 functions. We hit it.**

## The Solution

Deploy the **entire FastAPI application as ONE serverless function**.

### New Architecture

```
vercel.json:
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/api/index" }
  ]
}
```

This says: "Route ALL traffic to `/api/index`"

```
api/index.py:
from main import app  # Import the FastAPI app
```

This exports the FastAPI application.

**Result: ONE serverless function that handles ALL routes.**

### How It Works

1. **Request arrives**: `POST /webhooks/slack`
2. **Vercel routes to**: `/api/index` (the single function)
3. **FastAPI handles internally**: Routes to the `/webhooks/slack` endpoint
4. **Response returns**: Through the same path

### Benefits

- **1 function instead of 12** - Stays under Hobby plan limit
- **Faster cold starts** - Single function to warm up
- **Simpler deployment** - One artifact, one function
- **Correct FastAPI pattern** - FastAPI is designed as a single ASGI app

### File Structure

```
api/
├── index.py          # VERCEL ENTRYPOINT (the ONE function)
├── main.py           # FastAPI app with all routes
├── agents/           # NOT separate functions
├── workflows/        # NOT separate functions
├── tools/            # NOT separate functions
└── ...               # Everything else is imported code
```

## Best Practices (From Context7)

### Vercel + FastAPI Pattern

From `/websites/vercel` docs:

> "For Python frameworks like FastAPI, deploy the entire application as a single serverless function. The framework handles internal routing."

Example structure:
```
api/
├── index.py    # or app.py, main.py
└── ...         # supporting modules
```

### What NOT To Do

❌ **Per-file functions**: `api/**/*.py` creates function explosion
❌ **Nested route files**: Each route in separate file = separate function
❌ **Direct Python files in api/**: Vercel auto-detects as functions

### What TO Do

✅ **Single entrypoint**: One file exports the FastAPI app
✅ **Internal routing**: FastAPI handles all routes within the app
✅ **Rewrites for routing**: Use vercel.json rewrites to route to entrypoint
✅ **Module organization**: Keep code in subdirectories, import into main app

## Testing Locally

```bash
# Install dependencies
pip install -r api/requirements.txt

# Run locally (simulates Vercel environment)
cd api
python3 -m uvicorn main:app --reload

# Or use Vercel dev
vercel dev
```

## Deployment

```bash
# Deploy to Vercel
git push origin main

# Vercel will:
# 1. Find api/index.py
# 2. Create ONE function
# 3. Route all traffic through it
# 4. FastAPI handles internal routing
```

## Monitoring

Check function count:
- Vercel Dashboard → Project → Functions
- Should show: **1 function** (`api/index.py` or `/api/index`)

## The Philosophy

FastAPI is a **monolithic ASGI application**.
It's designed to handle routing internally.

Trying to split it into multiple serverless functions is:
- Fighting the framework
- Creating unnecessary complexity
- Hitting platform limits
- Slowing down deployments

**Ship the framework as designed. One app. One function. Done.**
