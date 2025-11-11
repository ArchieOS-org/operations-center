"""
Realtors API router following Context7 best practices.

Provides CRUD endpoints for realtor management.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Path
from ulid import ULID

from backend.models.realtor import (
    RealtorCreate,
    RealtorUpdate,
    Realtor,
    RealtorListResponse,
    RealtorSummary,
    RealtorStatus
)
from backend.database import realtors as realtors_db


# Initialize router with shared configuration
router = APIRouter(
    prefix="/realtors",
    tags=["realtors"],
    responses={
        404: {"description": "Realtor not found"},
        409: {"description": "Realtor already exists"}
    }
)


@router.post(
    "/",
    response_model=Realtor,
    status_code=201,
    summary="Create a new realtor",
    description="Create a new realtor with email, name, and optional license/brokerage info. Realtor ID (ULID) is auto-generated."
)
async def create_realtor(realtor_data: RealtorCreate) -> Realtor:
    """
    Create a new realtor.

    - **email**: Valid email address (must be unique)
    - **name**: Realtor's full name
    - **phone**: Optional phone number
    - **license_number**: Optional real estate license number
    - **brokerage**: Optional brokerage firm name
    - **slack_user_id**: Optional Slack user ID
    - **territories**: Optional list of service territories
    - **status**: Optional status (defaults to 'active')
    """
    # Generate ULID for new realtor
    realtor_id = str(ULID())

    try:
        return await realtors_db.create_realtor(realtor_data, realtor_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create realtor: {str(e)}"
        )


@router.get(
    "/",
    response_model=RealtorListResponse,
    summary="List realtors",
    description="Retrieve a paginated list of realtors with optional filters."
)
async def list_realtors(
    status: Optional[RealtorStatus] = Query(None, description="Filter by status"),
    brokerage: Optional[str] = Query(None, description="Filter by brokerage (partial match)"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
) -> RealtorListResponse:
    """
    List all realtors with optional filtering and pagination.

    - **status**: Filter by status (active, inactive, suspended, pending)
    - **brokerage**: Filter by brokerage name (partial match)
    - **limit**: Maximum number of results (1-100, default 50)
    - **offset**: Pagination offset (default 0)
    """
    try:
        return await realtors_db.list_realtors(
            status=status,
            brokerage=brokerage,
            limit=limit,
            offset=offset
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list realtors: {str(e)}"
        )


@router.get(
    "/{realtor_id}",
    response_model=Realtor,
    summary="Get realtor by ID",
    description="Retrieve a specific realtor by their realtor ID."
)
async def get_realtor(
    realtor_id: str = Path(..., description="Realtor ID (ULID)")
) -> Realtor:
    """
    Get a specific realtor by ID.

    - **realtor_id**: ULID of the realtor
    """
    realtor = await realtors_db.get_realtor_by_id(realtor_id)

    if not realtor:
        raise HTTPException(
            status_code=404,
            detail=f"Realtor with ID {realtor_id} not found"
        )

    return realtor


@router.get(
    "/email/{email}",
    response_model=Realtor,
    summary="Get realtor by email",
    description="Retrieve a specific realtor by their email address."
)
async def get_realtor_by_email(
    email: str = Path(..., description="Realtor email address")
) -> Realtor:
    """
    Get a specific realtor by email.

    - **email**: Email address of the realtor
    """
    realtor = await realtors_db.get_realtor_by_email(email)

    if not realtor:
        raise HTTPException(
            status_code=404,
            detail=f"Realtor with email {email} not found"
        )

    return realtor


@router.get(
    "/slack/{slack_user_id}",
    response_model=Realtor,
    summary="Get realtor by Slack user ID",
    description="Retrieve a specific realtor by their Slack user ID."
)
async def get_realtor_by_slack_id(
    slack_user_id: str = Path(..., description="Slack user ID")
) -> Realtor:
    """
    Get a specific realtor by Slack user ID.

    - **slack_user_id**: Slack user ID of the realtor
    """
    realtor = await realtors_db.get_realtor_by_slack_id(slack_user_id)

    if not realtor:
        raise HTTPException(
            status_code=404,
            detail=f"Realtor with Slack ID {slack_user_id} not found"
        )

    return realtor


@router.get(
    "/license/{license_number}",
    response_model=Realtor,
    summary="Get realtor by license number",
    description="Retrieve a specific realtor by their real estate license number."
)
async def get_realtor_by_license(
    license_number: str = Path(..., description="Real estate license number")
) -> Realtor:
    """
    Get a specific realtor by license number.

    - **license_number**: Real estate license number
    """
    realtor = await realtors_db.get_realtor_by_license_number(license_number)

    if not realtor:
        raise HTTPException(
            status_code=404,
            detail=f"Realtor with license number {license_number} not found"
        )

    return realtor


@router.put(
    "/{realtor_id}",
    response_model=Realtor,
    summary="Update realtor",
    description="Update an existing realtor's information."
)
async def update_realtor(
    realtor_id: str = Path(..., description="Realtor ID (ULID)"),
    realtor_data: RealtorUpdate = ...
) -> Realtor:
    """
    Update a realtor's information.

    - **realtor_id**: ULID of the realtor
    - **realtor_data**: Fields to update (all optional)

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    # Check if realtor exists
    existing = await realtors_db.get_realtor_by_id(realtor_id)
    if not existing:
        raise HTTPException(
            status_code=404,
            detail=f"Realtor with ID {realtor_id} not found"
        )

    try:
        return await realtors_db.update_realtor(realtor_id, realtor_data)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update realtor: {str(e)}"
        )


@router.delete(
    "/{realtor_id}",
    status_code=204,
    summary="Delete realtor",
    description="Soft delete a realtor (sets deleted_at timestamp)."
)
async def delete_realtor(
    realtor_id: str = Path(..., description="Realtor ID (ULID)")
):
    """
    Soft delete a realtor.

    - **realtor_id**: ULID of the realtor

    Note: This is a soft delete. The realtor record remains in the database
    with deleted_at timestamp set, but will not appear in queries.
    """
    deleted = await realtors_db.soft_delete_realtor(realtor_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail=f"Realtor with ID {realtor_id} not found"
        )

    return None
