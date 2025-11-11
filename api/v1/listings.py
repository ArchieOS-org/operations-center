"""
Vercel serverless entry point for listings endpoints.
Context7 Pattern: FastAPI app.include_router() for composition
Source: /fastapi/fastapi docs - "Include FastAPI APIRouters"
"""
from fastapi import FastAPI
from backend.routers.listings import router as listings_router

# Create FastAPI app
app = FastAPI(
    title="Operations Center - Listings API",
    description="Listing management endpoints for Operations Center",
    version="1.0.0"
)

# Include listings router
# Context7 Pattern: app.include_router() for modular routing
# Source: /fastapi/fastapi - "Include FastAPI APIRouters"
app.include_router(listings_router)

# Vercel serverless handler
handler = app
