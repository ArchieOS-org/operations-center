"""
Vercel serverless function entry point for listing tasks API.

Context7 Pattern: FastAPI app with include_router()
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""

from fastapi import FastAPI
from backend.routers.listing_tasks import router as listing_tasks_router

# Context7 Pattern: FastAPI app composition
# Source: /fastapi/fastapi - "Organize FastAPI Applications with APIRouter"
app = FastAPI(
    title="Operations Center - Listing Tasks API",
    version="2.0.0",
    description="Listing-specific task management endpoints"
)

# Include the listing_tasks router
# Context7 Pattern: app.include_router() for composition
app.include_router(listing_tasks_router)

# Vercel serverless handler
handler = app
