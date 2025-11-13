# Vercel Deployment Architecture

## The Problem We Solved

Vercel was creating **12 serverless functions** because:

1. **First Issue**: The old `vercel.json` pattern `api/**/*.py` explicitly created functions
2. **Deeper Issue**: Even without that pattern, **Vercel auto-detects EVERY Python file in api/ as a separate function**

Result:
- `api/agents/classifier.py` → Function 1
- `api/agents/orchestrator.py` → Function 2
- `api/workflows/slack_intake.py` → Function 3
- ... and so on

**Hobby plan limit: 12 functions. We hit it.**

## The Solution

Deploy the **entire FastAPI application as ONE serverless function** by:
1. **Moving all Python code OUT of api/ directory** (to prevent auto-detection)
2. **Single api/index.py file** that imports the app

### New Architecture

```
project/
├── api/
│   └── index.py          # ONLY Python file in api/ (Vercel entrypoint)
├── app/                  # ALL FastAPI code lives here
│   ├── main.py          # FastAPI app definition
│   ├── agents/          # Agent modules
│   ├── tools/           # Tool modules
│   ├── workflows/       # Workflow modules
│   └── ...              # All other Python code
├── vercel.json          # Routes all traffic to /api/index
└── requirements.txt     # Python dependencies
```

```
vercel.json:
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/api/index" }
  ]
}
```

```python
# api/index.py
import sys
from pathlib import Path

# Add app directory to Python path
app_dir = Path(__file__).parent.parent / "app"
sys.path.insert(0, str(app_dir))

from main import app  # Import the FastAPI app
```

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
