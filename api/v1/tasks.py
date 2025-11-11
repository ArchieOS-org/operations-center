"""
Vercel serverless function entry point for tasks API.
Context7 Pattern: FastAPI app with include_router()
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""
from fastapi import FastAPI
from backend.routers.tasks import router as tasks_router

# Context7 Pattern: FastAPI app composition
# Source: /fastapi/fastapi - "Organize FastAPI Applications with APIRouter"
app = FastAPI(
    title="Operations Center - Tasks API",
    version="1.0.0",
    description="Task management endpoints"
)

# Include the tasks router
# Context7 Pattern: app.include_router() for composition
app.include_router(tasks_router)

# Vercel serverless handler
handler = app
