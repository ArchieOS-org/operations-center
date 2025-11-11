"""
Vercel serverless function entry point for staff API.

Context7 Pattern: FastAPI app with include_router()
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""

from fastapi import FastAPI
from backend.routers.staff import router as staff_router

# Context7 Pattern: FastAPI app composition
# Source: /fastapi/fastapi - "Organize FastAPI Applications with APIRouter"
app = FastAPI(
    title="Operations Center - Staff API",
    version="2.0.0",
    description="Staff member management endpoints"
)

# Include the staff router
# Context7 Pattern: app.include_router() for composition
app.include_router(staff_router)

# Vercel serverless handler
handler = app
