"""
Vercel serverless function entry point for Slack messages API.

Context7 Pattern: FastAPI app with include_router()
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""

from fastapi import FastAPI
from backend.routers.slack_messages import router as slack_messages_router

# Context7 Pattern: FastAPI app composition
# Source: /fastapi/fastapi - "Organize FastAPI Applications with APIRouter"
app = FastAPI(
    title="Operations Center - Slack Messages API",
    version="2.0.0",
    description="Slack message tracking and processing endpoints"
)

# Include the slack_messages router
# Context7 Pattern: app.include_router() for composition
app.include_router(slack_messages_router)

# Vercel serverless handler
handler = app
