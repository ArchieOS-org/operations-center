"""
Vercel Serverless Function Entry Point

THE ONLY Python file in api/ directory.
All other code lives in app/ to prevent Vercel from creating multiple functions.

Architecture:
- api/index.py: Single serverless function entrypoint
- app/: All FastAPI code, agents, workflows, etc.
- Result: ONE function that handles ALL routes internally
"""

import sys
from pathlib import Path

# Add app directory to Python path
app_dir = Path(__file__).parent.parent / "app"
sys.path.insert(0, str(app_dir))

# Import FastAPI app from app directory
from main import app  # noqa: E402, F401

# Explicitly export for Vercel
__all__ = ["app"]

# This is the ONLY export. Vercel creates ONE function.
# FastAPI handles ALL routing internally.
