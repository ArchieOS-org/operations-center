"""
Vercel serverless function entry point for realtors API.

Context7 Pattern: FastAPI app with include_router()
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""

from fastapi import FastAPI
from backend.routers.realtors import router as realtors_router

# Context7 Pattern: FastAPI app composition
# Source: /fastapi/fastapi - "Organize FastAPI Applications with APIRouter"
app = FastAPI(
    title="Operations Center - Realtors API",
    version="2.0.0",
    description="Realtor management endpoints"
)

# Include the realtors router
# Context7 Pattern: app.include_router() for composition
app.include_router(realtors_router)

# Vercel serverless handler
handler = app
