"""
Vercel serverless function entry point for La-Paz Operations Center API.

Following Context7 pattern from /vercel-labs/ai-sdk-preview-python-streaming:
- Single entry point for entire FastAPI application
- Routes handled via vercel.json rewrites
- Avoids Hobby plan 12-function limit

Source: https://github.com/vercel-labs/ai-sdk-preview-python-streaming
"""

from backend.main import app

# Vercel serverless handler
# All requests to /api/* route through this single function
handler = app
