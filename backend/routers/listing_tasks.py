"""
Listing Tasks API router following Context7 best practices.

Provides CRUD endpoints for listing-specific task management.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Path
from ulid import ULID

from backend.models.listing_task import (
    ListingTaskCreate,
    ListingTaskUpdate,
    ListingTask,
    ListingTaskListResponse,
    TaskStatus,
    TaskCategory,
    VisibilityGroup
)
from backend.database import listing_tasks as listing_tasks_db


# Initialize router with shared configuration
router = APIRouter(
    prefix="/listing-tasks",
    tags=["listing-tasks"],
    responses={
        404: {"description": "Listing task not found"},
        409: {"description": "Listing task already exists"}
    }
)


@router.post(
    "/",
    response_model=ListingTask,
    status_code=201,
    summary="Create a new listing task",
    description="Create a new task associated with a specific listing. Task ID (ULID) is auto-generated."
)
async def create_listing_task(task_data: ListingTaskCreate) -> ListingTask:
    """
    Create a new listing task.

    - **listing_id**: ID of the associated listing (required)
    - **realtor_id**: ID of the realtor (optional)
    - **name**: Task name/description
    - **task_category**: One of: ADMIN, MARKETING, PHOTO, STAGING, INSPECTION, OTHER
    - **status**: Task status (defaults to 'OPEN')
    - **assigned_staff_id**: Staff member assigned to task (optional)
    - **visibility_group**: Who can see this task (optional)
    """
    # Generate ULID for new task
    task_id = str(ULID())

    try:
        return await listing_tasks_db.create_listing_task(task_data, task_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create listing task: {str(e)}"
        )


@router.get(
    "/",
    response_model=ListingTaskListResponse,
    summary="List listing tasks",
    description="Retrieve a paginated list of listing tasks with optional filters."
)
async def list_listing_tasks(
    listing_id: Optional[str] = Query(None, description="Filter by listing ID"),
    realtor_id: Optional[str] = Query(None, description="Filter by realtor ID"),
    assigned_staff_id: Optional[str] = Query(None, description="Filter by assigned staff ID"),
    status: Optional[TaskStatus] = Query(None, description="Filter by task status"),
    task_category: Optional[TaskCategory] = Query(None, description="Filter by task category"),
    visibility_group: Optional[VisibilityGroup] = Query(None, description="Filter by visibility group"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
) -> ListingTaskListResponse:
    """
    List all listing tasks with optional filtering and pagination.

    - **listing_id**: Filter by specific listing
    - **realtor_id**: Filter by specific realtor
    - **assigned_staff_id**: Filter by assigned staff member
    - **status**: Filter by status (OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED)
    - **task_category**: Filter by category
    - **visibility_group**: Filter by visibility
    - **limit**: Maximum number of results (1-100, default 50)
    - **offset**: Pagination offset (default 0)
    """
    try:
        return await listing_tasks_db.list_listing_tasks(
            listing_id=listing_id,
            realtor_id=realtor_id,
            assigned_staff_id=assigned_staff_id,
            status=status,
            task_category=task_category,
            visibility_group=visibility_group,
            limit=limit,
            offset=offset
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list listing tasks: {str(e)}"
        )


@router.get(
    "/{task_id}",
    response_model=ListingTask,
    summary="Get listing task by ID",
    description="Retrieve a specific listing task by its task ID."
)
async def get_listing_task(
    task_id: str = Path(..., description="Listing task ID (ULID)")
) -> ListingTask:
    """
    Get a specific listing task by ID.

    - **task_id**: ULID of the listing task
    """
    task = await listing_tasks_db.get_listing_task_by_id(task_id)

    if not task:
        raise HTTPException(
            status_code=404,
            detail=f"Listing task with ID {task_id} not found"
        )

    return task


@router.get(
    "/listing/{listing_id}",
    response_model=list[ListingTask],
    summary="Get all tasks for a listing",
    description="Retrieve all tasks associated with a specific listing."
)
async def get_listing_tasks_by_listing(
    listing_id: str = Path(..., description="Listing ID")
) -> list[ListingTask]:
    """
    Get all tasks for a specific listing.

    - **listing_id**: ID of the listing
    """
    try:
        return await listing_tasks_db.get_listing_tasks_by_listing(listing_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get tasks for listing: {str(e)}"
        )


@router.get(
    "/realtor/{realtor_id}",
    response_model=list[ListingTask],
    summary="Get all tasks for a realtor",
    description="Retrieve all listing tasks associated with a specific realtor."
)
async def get_listing_tasks_by_realtor(
    realtor_id: str = Path(..., description="Realtor ID")
) -> list[ListingTask]:
    """
    Get all listing tasks for a specific realtor.

    - **realtor_id**: ID of the realtor
    """
    try:
        return await listing_tasks_db.get_listing_tasks_by_realtor(realtor_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get tasks for realtor: {str(e)}"
        )


@router.get(
    "/staff/{staff_id}",
    response_model=list[ListingTask],
    summary="Get all tasks assigned to a staff member",
    description="Retrieve all listing tasks assigned to a specific staff member."
)
async def get_listing_tasks_by_staff(
    staff_id: str = Path(..., description="Staff ID")
) -> list[ListingTask]:
    """
    Get all listing tasks assigned to a specific staff member.

    - **staff_id**: ID of the staff member
    """
    try:
        return await listing_tasks_db.get_listing_tasks_by_staff(staff_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get tasks for staff: {str(e)}"
        )


@router.put(
    "/{task_id}",
    response_model=ListingTask,
    summary="Update listing task",
    description="Update an existing listing task's information."
)
async def update_listing_task(
    task_id: str = Path(..., description="Listing task ID (ULID)"),
    task_data: ListingTaskUpdate = ...
) -> ListingTask:
    """
    Update a listing task's information.

    - **task_id**: ULID of the listing task
    - **task_data**: Fields to update (all optional)

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    # Check if task exists
    existing = await listing_tasks_db.get_listing_task_by_id(task_id)
    if not existing:
        raise HTTPException(
            status_code=404,
            detail=f"Listing task with ID {task_id} not found"
        )

    try:
        return await listing_tasks_db.update_listing_task(task_id, task_data)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update listing task: {str(e)}"
        )


@router.delete(
    "/{task_id}",
    status_code=204,
    summary="Delete listing task",
    description="Soft delete a listing task (sets deleted_at timestamp)."
)
async def delete_listing_task(
    task_id: str = Path(..., description="Listing task ID (ULID)")
):
    """
    Soft delete a listing task.

    - **task_id**: ULID of the listing task

    Note: This is a soft delete. The task record remains in the database
    with deleted_at timestamp set, but will not appear in queries.
    """
    deleted = await listing_tasks_db.soft_delete_listing_task(task_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail=f"Listing task with ID {task_id} not found"
        )

    return None
