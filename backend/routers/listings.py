"""
Listings router using FastAPI APIRouter pattern.
Context7 Pattern: APIRouter with prefix, tags, and dependencies
Source: /fastapi/fastapi docs - "Bigger Applications - Multiple Files"
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional, Literal
from supabase import Client
from backend.models.listing import (
    ListingDetail,
    ListingListResponse,
    ListingDetailsResponse
)
from backend.models.user import User
from backend.middleware.auth import get_current_user
from backend.database.supabase_client import get_db
from backend.database import listings as listings_db


# Context7 Pattern: APIRouter with shared configuration
# Source: /fastapi/fastapi - "APIRouter with Shared Configuration"
router = APIRouter(
    prefix="/v1/operations/listings",
    tags=["listings"],
    dependencies=[Depends(get_current_user)],  # All routes require auth
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"}
    }
)


@router.get("", response_model=ListingListResponse)
async def list_listings(
    status: Optional[Literal["new", "in_progress", "completed"]] = Query(None, description="Filter by status"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(25, ge=1, le=100, description="Items per page"),
    sort_by: Literal["created_at", "due_date", "address"] = Query("created_at", description="Sort field"),
    include_deleted: bool = Query(False, description="Include deleted listings"),
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    List all listings with filters and pagination.

    Context7 Pattern: Query parameters with Literal types and Field validation
    Source: /fastapi/fastapi - "Query Parameters" + /pydantic/pydantic - "Literal types"
    """
    # Query listings
    listings, total = await listings_db.list_listings(
        db,
        status=status,
        page=page,
        limit=limit,
        sort_by=sort_by,
        include_deleted=include_deleted
    )

    # Calculate pagination
    total_pages = max(1, (total + limit - 1) // limit)
    has_more = page < total_pages

    return ListingListResponse(
        listings=listings,
        pagination={
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": total_pages,
            "has_more": has_more
        }
    )


@router.get("/{listing_id}", response_model=ListingDetail)
async def get_listing(
    listing_id: str,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Get a single listing by ID.

    Context7 Pattern: Path parameter with dependency injection
    Source: /fastapi/fastapi - "Path Parameters"
    """
    listing = await listings_db.get_listing_by_id(db, listing_id)

    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    return listing


@router.get("/{listing_id}/details", response_model=ListingDetailsResponse)
async def get_listing_details(
    listing_id: str,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Get full listing details including property info, history, tasks, and notes.

    Context7 Pattern: Nested response models with parallel data fetching
    Source: /fastapi/fastapi - "Response Model" + async/await patterns
    """
    # Get listing
    listing = await listings_db.get_listing_by_id(db, listing_id)
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    # Fetch related data in parallel (simulated - Supabase Python client is sync internally)
    # In production, could use asyncio.gather for true parallelism with async HTTP calls
    property_details = await listings_db.get_listing_property_details(db, listing_id)
    history = await listings_db.get_listing_history(db, listing_id, limit=100)
    tasks = await listings_db.get_listing_tasks(db, listing_id, limit=100)
    notes = await listings_db.get_listing_notes(db, listing_id, limit=100)

    return ListingDetailsResponse(
        listing=listing,
        details=property_details or {},
        history=history,
        tasks=tasks,
        notes=notes
    )
