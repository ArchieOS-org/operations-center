"""
Staff database access layer using Supabase Python client.

Following Context7 best practices for Supabase operations.
"""

from typing import Optional
from datetime import datetime
from fastapi import HTTPException
from postgrest.exceptions import APIError

from backend.database.supabase_client import get_supabase_client
from backend.models.staff import StaffCreate, StaffUpdate, StaffMember


async def create_staff(staff_data: StaffCreate, staff_id: str) -> StaffMember:
    """Create a new staff member."""
    db = get_supabase_client()

    try:
        data = staff_data.model_dump()
        data["staff_id"] = staff_id

        response = db.table("staff").insert(data).execute()

        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create staff member")

        return StaffMember(**response.data[0])

    except APIError as e:
        if "duplicate key" in str(e).lower():
            raise HTTPException(status_code=409, detail="Staff member with this email already exists")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_staff_by_id(staff_id: str) -> Optional[StaffMember]:
    """Get staff member by ID."""
    db = get_supabase_client()

    try:
        response = (
            db.table("staff")
            .select("*")
            .eq("staff_id", staff_id)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return StaffMember(**response.data[0])

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_staff_by_email(email: str) -> Optional[StaffMember]:
    """Get staff member by email."""
    db = get_supabase_client()

    try:
        response = (
            db.table("staff")
            .select("*")
            .eq("email", email)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return StaffMember(**response.data[0])

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def list_staff(
    role: Optional[str] = None,
    status: Optional[str] = None,
    page: int = 1,
    page_size: int = 50
) -> tuple[list[StaffMember], int]:
    """List staff members with optional filtering and pagination."""
    db = get_supabase_client()

    try:
        query = db.table("staff").select("*", count="exact").is_("deleted_at", "null")

        if role:
            query = query.eq("role", role)

        if status:
            query = query.eq("status", status)

        # Pagination
        offset = (page - 1) * page_size
        query = query.order("created_at", desc=True).range(offset, offset + page_size - 1)

        response = query.execute()

        staff_list = [StaffMember(**item) for item in response.data]
        total = response.count if response.count is not None else 0

        return staff_list, total

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def update_staff(staff_id: str, updates: StaffUpdate) -> Optional[StaffMember]:
    """Update staff member."""
    db = get_supabase_client()

    try:
        # Filter out None values
        update_data = {k: v for k, v in updates.model_dump().items() if v is not None}

        if not update_data:
            # No updates provided, just return current record
            return await get_staff_by_id(staff_id)

        response = (
            db.table("staff")
            .update(update_data)
            .eq("staff_id", staff_id)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return StaffMember(**response.data[0])

    except APIError as e:
        if "duplicate key" in str(e).lower():
            raise HTTPException(status_code=409, detail="Email already in use")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def soft_delete_staff(staff_id: str) -> bool:
    """Soft delete staff member."""
    db = get_supabase_client()

    try:
        response = (
            db.table("staff")
            .update({"deleted_at": datetime.utcnow().isoformat()})
            .eq("staff_id", staff_id)
            .is_("deleted_at", "null")
            .execute()
        )

        return len(response.data) > 0

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_staff_by_slack_id(slack_user_id: str) -> Optional[StaffMember]:
    """Get staff member by Slack user ID."""
    db = get_supabase_client()

    try:
        response = (
            db.table("staff")
            .select("*")
            .eq("slack_user_id", slack_user_id)
            .is_("deleted_at", "null")
            .execute()
        )

        if not response.data:
            return None

        return StaffMember(**response.data[0])

    except APIError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
