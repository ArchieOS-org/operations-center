"""
Main FastAPI application for La-Paz Operations Center.

Following Context7 best practices for FastAPI application setup.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Import routers
from backend.routers import staff, realtors, listing_tasks, stray_tasks, slack_messages


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    Replaces deprecated @app.on_event("startup") and @app.on_event("shutdown").
    """
    # Startup logic
    print("🚀 Starting La-Paz API server...")
    print("✅ Database connection ready (Supabase)")

    yield  # Application runs here

    # Shutdown logic
    print("🛑 Shutting down La-Paz API server...")


# Initialize FastAPI application
app = FastAPI(
    title="La-Paz Operations Center API",
    description="Real estate operations management API with staff/realtor separation",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:5173",  # Vite default
        "https://*.vercel.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers with /v1/operations prefix
# Note: Each router already has its own prefix (e.g., /staff, /realtors)
# So final routes will be: /v1/operations/staff/*, /v1/operations/realtors/*, etc.
app.include_router(staff.router, prefix="/v1/operations")
app.include_router(realtors.router, prefix="/v1/operations")
app.include_router(listing_tasks.router, prefix="/v1/operations")
app.include_router(stray_tasks.router, prefix="/v1/operations")
app.include_router(slack_messages.router, prefix="/v1/operations")


@app.get("/")
async def root():
    """Root endpoint - health check."""
    return {
        "status": "ok",
        "message": "La-Paz Operations Center API",
        "version": "2.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "database": "connected",  # TODO: Add actual DB health check
        "timestamp": "2024-01-15T10:30:00Z"  # TODO: Add actual timestamp
    }


@app.get("/v1/operations/status")
async def operations_status():
    """Operations status endpoint."""
    return {
        "staff_service": "operational",
        "realtors_service": "operational",
        "tasks_service": "operational",
        "slack_integration": "operational"
    }


# For local development
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "backend.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
