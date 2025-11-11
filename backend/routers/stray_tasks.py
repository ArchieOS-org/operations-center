"""
Stray Tasks API router following Context7 best practices.

Provides CRUD endpoints for realtor-specific task management (not tied to listings).
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Path
from ulid import ULID

from backend.models.stray_task import (
    StrayTaskCreate,
    StrayTaskUpdate,
    StrayTask,
    StrayTaskListResponse,
    TaskStatus
)
from backend.database import stray_tasks as stray_tasks_db


# Initialize router with shared configuration
router = APIRouter(
    prefix="/stray-tasks",
    tags=["stray-tasks"],
    responses={
        404: {"description": "Stray task not found"},
        409: {"description": "Stray task already exists"}
    }
)


@router.post(
    "/",
    response_model=StrayTask,
    status_code=201,
    summary="Create a new stray task",
    description="Create a new realtor-specific task not tied to a listing. Task ID (ULID) is auto-generated."
)
async def create_stray_task(task_data: StrayTaskCreate) -> StrayTask:
    """
    Create a new stray task.

    - **realtor_id**: ID of the realtor (required)
    - **task_key**: Classification system identifier
    - **name**: Task name/description
    - **status**: Task status (defaults to 'OPEN')
    - **assigned_staff_id**: Staff member assigned to task (optional)
    - **notes**: Additional task notes (optional)
    """
    # Generate ULID for new task
    task_id = str(ULID())

    try:
        return await stray_tasks_db.create_stray_task(task_data, task_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create stray task: {str(e)}"
        )


@router.get(
    "/",
    response_model=StrayTaskListResponse,
    summary="List stray tasks",
    description="Retrieve a paginated list of stray tasks with optional filters."
)
async def list_stray_tasks(
    realtor_id: Optional[str] = Query(None, description="Filter by realtor ID"),
    assigned_staff_id: Optional[str] = Query(None, description="Filter by assigned staff ID"),
    status: Optional[TaskStatus] = Query(None, description="Filter by task status"),
    task_key: Optional[str] = Query(None, description="Filter by task key"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
) -> StrayTaskListResponse:
    """
    List all stray tasks with optional filtering and pagination.

    - **realtor_id**: Filter by specific realtor
    - **assigned_staff_id**: Filter by assigned staff member
    - **status**: Filter by status (OPEN, CLAIMED, IN_PROGRESS, DONE, FAILED, CANCELLED)
    - **task_key**: Filter by classification task key
    - **limit**: Maximum number of results (1-100, default 50)
    - **offset**: Pagination offset (default 0)
    """
    try:
        return await stray_tasks_db.list_stray_tasks(
            realtor_id=realtor_id,
            assigned_staff_id=assigned_staff_id,
            status=status,
            task_key=task_key,
            limit=limit,
            offset=offset
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list stray tasks: {str(e)}"
        )


@router.get(
    "/{task_id}",
    response_model=StrayTask,
    summary="Get stray task by ID",
    description="Retrieve a specific stray task by its task ID."
)
async def get_stray_task(
    task_id: str = Path(..., description="Stray task ID (ULID)")
) -> StrayTask:
    """
    Get a specific stray task by ID.

    - **task_id**: ULID of the stray task
    """
    task = await stray_tasks_db.get_stray_task_by_id(task_id)

    if not task:
        raise HTTPException(
            status_code=404,
            detail=f"Stray task with ID {task_id} not found"
        )

    return task


@router.get(
    "/key/{realtor_id}/{task_key}",
    response_model=StrayTask,
    summary="Get stray task by realtor and task key",
    description="Retrieve a specific stray task by realtor ID and task key combination."
)
async def get_stray_task_by_key(
    realtor_id: str = Path(..., description="Realtor ID"),
    task_key: str = Path(..., description="Task key from classification")
) -> StrayTask:
    """
    Get a specific stray task by realtor ID and task key.

    - **realtor_id**: ID of the realtor
    - **task_key**: Classification system task key
    """
    task = await stray_tasks_db.get_stray_task_by_key(realtor_id, task_key)

    if not task:
        raise HTTPException(
            status_code=404,
            detail=f"Stray task with key '{task_key}' for realtor {realtor_id} not found"
        )

    return task


@router.get(
    "/realtor/{realtor_id}",
    response_model=list[StrayTask],
    summary="Get all tasks for a realtor",
    description="Retrieve all stray tasks for a specific realtor."
)
async def get_stray_tasks_by_realtor(
    realtor_id: str = Path(..., description="Realtor ID")
) -> list[StrayTask]:
    """
    Get all stray tasks for a specific realtor.

    - **realtor_id**: ID of the realtor
    """
    try:
        return await stray_tasks_db.get_stray_tasks_by_realtor(realtor_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get tasks for realtor: {str(e)}"
        )


@router.get(
    "/staff/{staff_id}",
    response_model=list[StrayTask],
    summary="Get all tasks assigned to a staff member",
    description="Retrieve all stray tasks assigned to a specific staff member."
)
async def get_stray_tasks_by_staff(
    staff_id: str = Path(..., description="Staff ID")
) -> list[StrayTask]:
    """
    Get all stray tasks assigned to a specific staff member.

    - **staff_id**: ID of the staff member
    """
    try:
        return await stray_tasks_db.get_stray_tasks_by_staff(staff_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get tasks for staff: {str(e)}"
        )


@router.get(
    "/open/",
    response_model=list[StrayTask],
    summary="Get all open stray tasks",
    description="Retrieve all open (not completed/cancelled) stray tasks, optionally filtered by realtor."
)
async def get_open_stray_tasks(
    realtor_id: Optional[str] = Query(None, description="Filter by realtor ID")
) -> list[StrayTask]:
    """
    Get all open stray tasks.

    - **realtor_id**: Optional filter by specific realtor
    """
    try:
        return await stray_tasks_db.get_open_stray_tasks(realtor_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get open tasks: {str(e)}"
        )


@router.put(
    "/{task_id}",
    response_model=StrayTask,
    summary="Update stray task",
    description="Update an existing stray task's information."
)
async def update_stray_task(
    task_id: str = Path(..., description="Stray task ID (ULID)"),
    task_data: StrayTaskUpdate = ...
) -> StrayTask:
    """
    Update a stray task's information.

    - **task_id**: ULID of the stray task
    - **task_data**: Fields to update (all optional)

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    # Check if task exists
    existing = await stray_tasks_db.get_stray_task_by_id(task_id)
    if not existing:
        raise HTTPException(
            status_code=404,
            detail=f"Stray task with ID {task_id} not found"
        )

    try:
        return await stray_tasks_db.update_stray_task(task_id, task_data)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update stray task: {str(e)}"
        )


@router.delete(
    "/{task_id}",
    status_code=204,
    summary="Delete stray task",
    description="Soft delete a stray task (sets deleted_at timestamp)."
)
async def delete_stray_task(
    task_id: str = Path(..., description="Stray task ID (ULID)")
):
    """
    Soft delete a stray task.

    - **task_id**: ULID of the stray task

    Note: This is a soft delete. The task record remains in the database
    with deleted_at timestamp set, but will not appear in queries.
    """
    deleted = await stray_tasks_db.soft_delete_stray_task(task_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail=f"Stray task with ID {task_id} not found"
        )

    return None
