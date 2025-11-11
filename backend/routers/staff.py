"""
Staff API router following Context7 best practices.

Provides CRUD endpoints for staff member management.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Path
from ulid import ULID

from backend.models.staff import (
    StaffCreate,
    StaffUpdate,
    StaffMember,
    StaffListResponse,
    StaffSummary,
    StaffRole,
    StaffStatus
)
from backend.database import staff as staff_db


# Initialize router with shared configuration
router = APIRouter(
    prefix="/staff",
    tags=["staff"],
    responses={
        404: {"description": "Staff member not found"},
        409: {"description": "Staff member already exists"}
    }
)


@router.post(
    "/",
    response_model=StaffMember,
    status_code=201,
    summary="Create a new staff member",
    description="Create a new staff member with email, name, and role. Staff ID (ULID) is auto-generated."
)
async def create_staff_member(staff_data: StaffCreate) -> StaffMember:
    """
    Create a new staff member.

    - **email**: Valid email address (must be unique)
    - **name**: Staff member's full name
    - **role**: One of: admin, operations, marketing, support
    - **slack_user_id**: Optional Slack user ID
    - **phone**: Optional phone number
    - **status**: Optional status (defaults to 'active')
    """
    # Generate ULID for new staff member
    staff_id = str(ULID())

    try:
        return await staff_db.create_staff(staff_data, staff_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create staff member: {str(e)}"
        )


@router.get(
    "/",
    response_model=StaffListResponse,
    summary="List staff members",
    description="Retrieve a paginated list of staff members with optional filters."
)
async def list_staff_members(
    role: Optional[StaffRole] = Query(None, description="Filter by role"),
    status: Optional[StaffStatus] = Query(None, description="Filter by status"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
) -> StaffListResponse:
    """
    List all staff members with optional filtering and pagination.

    - **role**: Filter by staff role (admin, operations, marketing, support)
    - **status**: Filter by status (active, inactive, suspended)
    - **limit**: Maximum number of results (1-100, default 50)
    - **offset**: Pagination offset (default 0)
    """
    try:
        return await staff_db.list_staff(
            role=role,
            status=status,
            limit=limit,
            offset=offset
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list staff members: {str(e)}"
        )


@router.get(
    "/{staff_id}",
    response_model=StaffMember,
    summary="Get staff member by ID",
    description="Retrieve a specific staff member by their staff ID."
)
async def get_staff_member(
    staff_id: str = Path(..., description="Staff member ID (ULID)")
) -> StaffMember:
    """
    Get a specific staff member by ID.

    - **staff_id**: ULID of the staff member
    """
    staff = await staff_db.get_staff_by_id(staff_id)

    if not staff:
        raise HTTPException(
            status_code=404,
            detail=f"Staff member with ID {staff_id} not found"
        )

    return staff


@router.get(
    "/email/{email}",
    response_model=StaffMember,
    summary="Get staff member by email",
    description="Retrieve a specific staff member by their email address."
)
async def get_staff_member_by_email(
    email: str = Path(..., description="Staff member email address")
) -> StaffMember:
    """
    Get a specific staff member by email.

    - **email**: Email address of the staff member
    """
    staff = await staff_db.get_staff_by_email(email)

    if not staff:
        raise HTTPException(
            status_code=404,
            detail=f"Staff member with email {email} not found"
        )

    return staff


@router.get(
    "/slack/{slack_user_id}",
    response_model=StaffMember,
    summary="Get staff member by Slack user ID",
    description="Retrieve a specific staff member by their Slack user ID."
)
async def get_staff_member_by_slack_id(
    slack_user_id: str = Path(..., description="Slack user ID")
) -> StaffMember:
    """
    Get a specific staff member by Slack user ID.

    - **slack_user_id**: Slack user ID of the staff member
    """
    staff = await staff_db.get_staff_by_slack_id(slack_user_id)

    if not staff:
        raise HTTPException(
            status_code=404,
            detail=f"Staff member with Slack ID {slack_user_id} not found"
        )

    return staff


@router.put(
    "/{staff_id}",
    response_model=StaffMember,
    summary="Update staff member",
    description="Update an existing staff member's information."
)
async def update_staff_member(
    staff_id: str = Path(..., description="Staff member ID (ULID)"),
    staff_data: StaffUpdate = ...
) -> StaffMember:
    """
    Update a staff member's information.

    - **staff_id**: ULID of the staff member
    - **staff_data**: Fields to update (all optional)

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    # Check if staff exists
    existing = await staff_db.get_staff_by_id(staff_id)
    if not existing:
        raise HTTPException(
            status_code=404,
            detail=f"Staff member with ID {staff_id} not found"
        )

    try:
        return await staff_db.update_staff(staff_id, staff_data)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update staff member: {str(e)}"
        )


@router.delete(
    "/{staff_id}",
    status_code=204,
    summary="Delete staff member",
    description="Soft delete a staff member (sets deleted_at timestamp)."
)
async def delete_staff_member(
    staff_id: str = Path(..., description="Staff member ID (ULID)")
):
    """
    Soft delete a staff member.

    - **staff_id**: ULID of the staff member

    Note: This is a soft delete. The staff member record remains in the database
    with deleted_at timestamp set, but will not appear in queries.
    """
    deleted = await staff_db.soft_delete_staff(staff_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail=f"Staff member with ID {staff_id} not found"
        )

    return None
