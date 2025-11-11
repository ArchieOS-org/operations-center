"""
Listing database operations using Supabase Python client.
Context7 Pattern: Async query functions with error handling
Source: /supabase/supabase-py - "Async queries, filtering, ordering"
"""
from typing import Optional, List
from supabase import Client
from backend.models.listing import ListingDetail, ListingPropertyDetails, ListingHistoryEvent, ListingTaskSummary, ListingNote
from fastapi import HTTPException


async def get_listing_by_id(db: Client, listing_id: str) -> Optional[ListingDetail]:
    """
    Get a single listing by ID.

    Context7 Pattern: .from_().select().eq().execute()
    Source: /supabase/supabase-py - "Select Data from Supabase Table"

    Args:
        db: Supabase client instance
        listing_id: Listing identifier

    Returns:
        ListingDetail or None if not found
    """
    try:
        response = db.table("listings").select("*").eq("listing_id", listing_id).is_("deleted_at", None).execute()

        if not response.data or len(response.data) == 0:
            return None

        row = response.data[0]
        return ListingDetail(
            id=row["listing_id"],
            address=row.get("address_string", ""),
            status=row.get("status", "new"),
            assignee=row.get("assignee"),
            agent_id=row.get("agent_id"),
            due_date=row.get("due_date"),
            progress=row.get("progress"),
            type=row.get("type"),
            created_at=row["created_at"],
            updated_at=row["updated_at"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def list_listings(
    db: Client,
    status: Optional[str] = None,
    page: int = 1,
    limit: int = 25,
    sort_by: str = "created_at",
    include_deleted: bool = False
) -> tuple[List[ListingDetail], int]:
    """
    List listings with filters and pagination.

    Context7 Pattern: Chained query builder with filters
    Source: /supabase/supabase-py - "Select Specific Columns" + filtering

    Args:
        db: Supabase client
        status: Optional status filter
        page: Page number (1-indexed)
        limit: Results per page
        sort_by: Sort field (created_at, due_date, address)
        include_deleted: Whether to include deleted listings

    Returns:
        Tuple of (listings list, total count)
    """
    try:
        # Build base query
        query = db.table("listings").select("*", count="exact")

        # Filter deleted
        if not include_deleted:
            query = query.is_("deleted_at", None)

        # Apply filters
        if status:
            query = query.eq("status", status)

        # Apply sorting
        sort_field = "created_at"
        if sort_by == "due_date":
            sort_field = "due_date"
        elif sort_by == "address":
            sort_field = "address_string"

        query = query.order(sort_field, desc=(sort_by == "created_at"))

        # Apply pagination
        offset = (page - 1) * limit
        query = query.range(offset, offset + limit - 1)

        # Execute query
        response = query.execute()

        # Parse results
        listings = [
            ListingDetail(
                id=row["listing_id"],
                address=row.get("address_string", ""),
                status=row.get("status", "new"),
                assignee=row.get("assignee"),
                agent_id=row.get("agent_id"),
                due_date=row.get("due_date"),
                progress=row.get("progress"),
                type=row.get("type"),
                created_at=row["created_at"],
                updated_at=row["updated_at"]
            )
            for row in response.data
        ]
        total = response.count if response.count is not None else 0

        return listings, total
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_listing_property_details(db: Client, listing_id: str) -> Optional[ListingPropertyDetails]:
    """
    Get property details for a listing.

    Context7 Pattern: .select().eq().execute()
    Source: /supabase/supabase-py

    Args:
        db: Supabase client
        listing_id: Listing identifier

    Returns:
        ListingPropertyDetails or None if not found
    """
    try:
        response = db.table("listing_details").select("*").eq("listing_id", listing_id).execute()

        if not response.data or len(response.data) == 0:
            # Return default details if none exist
            return ListingPropertyDetails(
                property_type=None,
                bedrooms=0,
                bathrooms=0,
                sqft=0,
                year_built=0,
                list_price=0,
                notes=None
            )

        row = response.data[0]
        return ListingPropertyDetails(
            property_type=row.get("property_type"),
            bedrooms=row.get("bedrooms", 0),
            bathrooms=row.get("bathrooms", 0),
            sqft=row.get("sqft", 0),
            year_built=row.get("year_built", 0),
            list_price=row.get("list_price", 0),
            notes=row.get("notes")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_listing_history(db: Client, listing_id: str, limit: int = 100) -> List[ListingHistoryEvent]:
    """
    Get history events for a listing.

    Context7 Pattern: .select().eq().order().execute()
    Source: /supabase/supabase-py

    Args:
        db: Supabase client
        listing_id: Listing identifier
        limit: Maximum number of events

    Returns:
        List of history events
    """
    try:
        entity_key = f"listing#{listing_id}"
        response = db.table("audit_log").select("*").eq("entity_key", entity_key).order("timestamp", desc=True).limit(limit).execute()

        return [
            ListingHistoryEvent(
                id=row["event_id"],
                action=row["action"],
                performed_by=row.get("performed_by"),
                timestamp=row["timestamp"],
                changes=row.get("changes"),
                content=row.get("content")
            )
            for row in response.data
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_listing_tasks(db: Client, listing_id: str, limit: int = 100) -> List[ListingTaskSummary]:
    """
    Get tasks associated with a listing.

    Context7 Pattern: .select().eq().order().execute()
    Source: /supabase/supabase-py

    Args:
        db: Supabase client
        listing_id: Listing identifier
        limit: Maximum number of tasks

    Returns:
        List of task summaries
    """
    try:
        response = db.table("tasks").select("task_id, name, status, assignee_id, task_category").eq("listing_id", listing_id).is_("deleted_at", None).order("created_at", desc=True).limit(limit).execute()

        return [
            ListingTaskSummary(
                id=row["task_id"],
                title=row["name"],
                status=row["status"],
                assignee=row.get("assignee_id"),
                task_category=row.get("task_category")
            )
            for row in response.data
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_listing_notes(db: Client, listing_id: str, limit: int = 100) -> List[ListingNote]:
    """
    Get notes for a listing.

    Context7 Pattern: .select().eq().order().execute()
    Source: /supabase/supabase-py

    Args:
        db: Supabase client
        listing_id: Listing identifier
        limit: Maximum number of notes

    Returns:
        List of listing notes
    """
    try:
        response = db.table("listing_notes").select("*").eq("listing_id", listing_id).order("created_at", desc=False).limit(limit).execute()

        return [
            ListingNote(
                id=row["note_id"],
                content=row["content"],
                type=row.get("type", "general"),
                created_by=row.get("created_by"),
                created_at=row["created_at"]
            )
            for row in response.data
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
