"""
Vercel serverless function entry point for stray tasks API.

Context7 Pattern: FastAPI app with include_router()
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""

from fastapi import FastAPI
from backend.routers.stray_tasks import router as stray_tasks_router

# Context7 Pattern: FastAPI app composition
# Source: /fastapi/fastapi - "Organize FastAPI Applications with APIRouter"
app = FastAPI(
    title="Operations Center - Stray Tasks API",
    version="2.0.0",
    description="Realtor-specific task management endpoints (not tied to listings)"
)

# Include the stray_tasks router
# Context7 Pattern: app.include_router() for composition
app.include_router(stray_tasks_router)

# Vercel serverless handler
handler = app
