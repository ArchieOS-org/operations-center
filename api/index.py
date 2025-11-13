"""
Vercel Serverless Function Entry Point

Imports the FastAPI app from main.py and exposes it as a serverless handler.
Context7 Pattern: Vercel Python functions need to export `app` or `handler`
Source: /vercel/vercel Python serverless functions docs
"""

from .main import app

# Vercel will automatically handle the app as a serverless function
