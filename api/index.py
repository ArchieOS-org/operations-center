"""
Vercel Serverless Function Entry Point

Single entrypoint for the entire FastAPI application.
Vercel routes all traffic here, and FastAPI handles internal routing.

CRITICAL: This creates ONE serverless function, not 12.
The old pattern (api/**/*.py) created a function PER FILE.
This pattern deploys the entire FastAPI app as a single function.
"""

from main import app

# Export the app for Vercel
# Vercel will create ONE function at /api/index
# FastAPI handles all routing internally (/webhooks/slack, /classify, etc.)
