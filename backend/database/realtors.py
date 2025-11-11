"""
Realtors database access layer using Supabase Python client.

Following Context7 best practices for Supabase operations.
"""

from typing import Optional
from datetime import datetime
from fastapi import HTTPException
from postgrest.exceptions import APIError

from backend.database.supabase_client import get_supabase_client
from backend.models.realtor import RealtorCreate, RealtorUpdate, Realtor


async def create_realtor(realtor_data: RealtorCreate, realtor_id: str) -> Realtor:
    """Create a new realtor."""
    db = get_supabase_client()

    try:
        data = realtor_data.model_dump()
        data["realtor_id"] = realtor_id

        response = db.table("realtors").insert(data).execute()

        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create realtor")

        return Realtor(**response.data[0])

    except APIError as e:
        if "duplicate key" in str(e).lower():
            raise HTTPException(status_code=409, detail="Realtor with this email already exists")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_realtor_by_id(realtor_id: str) -> Optional[Realtor]:
    """Get realtor by ID."""
    db = get_supabase_client()

    try:
        response = (
            db.table("realtors")
            .select("*")
            .eq("realtor_id", realtor_id)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return Realtor(**response.data[0])

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def list_realtors(
    status: Optional[str] = None,
    brokerage: Optional[str] = None,
    page: int = 1,
    page_size: int = 50
) -> tuple[list[Realtor], int]:
    """List realtors with optional filtering and pagination."""
    db = get_supabase_client()

    try:
        query = db.table("realtors").select("*", count="exact").is_("deleted_at", "null")

        if status:
            query = query.eq("status", status)
        if brokerage:
            query = query.ilike("brokerage", f"%{brokerage}%")

        offset = (page - 1) * page_size
        query = query.order("created_at", desc=True).range(offset, offset + page_size - 1)

        response = query.execute()

        realtors = [Realtor(**item) for item in response.data]
        total = response.count if response.count is not None else 0

        return realtors, total

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def update_realtor(realtor_id: str, updates: RealtorUpdate) -> Optional[Realtor]:
    """Update realtor."""
    db = get_supabase_client()

    try:
        update_data = {k: v for k, v in updates.model_dump().items() if v is not None}

        if not update_data:
            return await get_realtor_by_id(realtor_id)

        response = (
            db.table("realtors")
            .update(update_data)
            .eq("realtor_id", realtor_id)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return Realtor(**response.data[0])

    except APIError as e:
        if "duplicate key" in str(e).lower():
            raise HTTPException(status_code=409, detail="Email or license number already in use")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def soft_delete_realtor(realtor_id: str) -> bool:
    """Soft delete realtor."""
    db = get_supabase_client()

    try:
        response = (
            db.table("realtors")
            .update({"deleted_at": datetime.utcnow().isoformat()})
            .eq("realtor_id", realtor_id)
            .is_("deleted_at", "null")
            .execute()
        )

        return len(response.data) > 0

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_realtor_by_slack_id(slack_user_id: str) -> Optional[Realtor]:
    """Get realtor by Slack user ID."""
    db = get_supabase_client()

    try:
        response = (
            db.table("realtors")
            .select("*")
            .eq("slack_user_id", slack_user_id)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return Realtor(**response.data[0])

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
