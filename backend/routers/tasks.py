"""
Tasks router using FastAPI APIRouter pattern.
Context7 Pattern: APIRouter with prefix, tags, and dependencies
Source: /fastapi/fastapi docs - "Bigger Applications - Multiple Files"
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from supabase import Client
from backend.models.task import (
    TaskDetail,
    TaskListResponse,
    TaskClaimRequest,
    TaskCompleteRequest,
    TaskReopenRequest,
    TaskNoteCreate,
    TaskNote
)
from backend.models.user import User
from backend.middleware.auth import get_current_user
from backend.database.supabase_client import get_db
from backend.database import tasks as tasks_db
from backend.services.authz import (
    can_claim_task,
    can_unclaim_task,
    can_complete_task,
    can_reopen_task,
    can_delete_task,
    require_admin
)

# Context7 Pattern: APIRouter with shared configuration
# Source: /fastapi/fastapi - "APIRouter with Shared Configuration"
router = APIRouter(
    prefix="/v1/operations/tasks",
    tags=["tasks"],
    dependencies=[Depends(get_current_user)],  # All routes require auth
    responses={
        404: {"description": "Not found"},
        401: {"description": "Not authenticated"}
    }
)


@router.get("/{listing_id}", response_model=TaskListResponse)
async def list_tasks(
    listing_id: str,
    status: Optional[str] = Query(None, description="Filter by status"),
    assigned_to: Optional[str] = Query(None, description="Filter by assignee"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(25, ge=1, le=100, description="Items per page"),
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    List all tasks for a specific listing.

    Context7 Pattern: FastAPI dependency injection with Depends()
    Source: /fastapi/fastapi - "Implement Dependency Injection"
    """
    # Build query
    query = db.table('tasks')\
        .select('*')\
        .eq('listing_id', listing_id)\
        .is_('deleted_at', 'null')

    if status:
        query = query.eq('status', status)

    if assigned_to:
        query = query.eq('assignee_id', assigned_to)

    # Execute query with pagination
    offset = (page - 1) * limit
    response = await query\
        .order('priority', desc=True)\
        .order('due_date')\
        .range(offset, offset + limit)\
        .execute()

    tasks = [TaskDetail(**task) for task in response.data]

    # TODO: Get total count for pagination
    total = len(tasks)
    total_pages = max(1, (total + limit - 1) // limit)

    return TaskListResponse(
        tasks=tasks,
        pagination={
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": total_pages,
            "has_more": page < total_pages
        }
    )


@router.post("/{task_id}/claim", response_model=TaskDetail)
async def claim_task(
    task_id: str,
    data: TaskClaimRequest,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Claim a task for the current user.

    Context7 Pattern: Pydantic model validation for request body
    """
    # Get task
    task_response = await db.table('tasks')\
        .select('*')\
        .eq('task_id', task_id)\
        .is_('deleted_at', 'null')\
        .single()\
        .execute()

    if not task_response.data:
        raise HTTPException(status_code=404, detail="Task not found")

    task = task_response.data

    # Check if already claimed
    if task['status'] == 'CLAIMED':
        raise HTTPException(status_code=400, detail="Task already claimed")

    # Update task
    from datetime import datetime, UTC
    update_response = await db.table('tasks')\
        .update({
            'status': 'CLAIMED',
            'assignee_id': user.user_id,
            'claimed_at': datetime.now(UTC).isoformat(),
            'updated_at': datetime.now(UTC).isoformat()
        })\
        .eq('task_id', task_id)\
        .select('*')\
        .single()\
        .execute()

    return TaskDetail(**update_response.data)


@router.post("/{task_id}/complete", response_model=TaskDetail)
async def complete_task(
    task_id: str,
    data: TaskCompleteRequest,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """Mark a task as completed."""
    # Get task
    task_response = await db.table('tasks')\
        .select('*')\
        .eq('task_id', task_id)\
        .is_('deleted_at', 'null')\
        .single()\
        .execute()

    if not task_response.data:
        raise HTTPException(status_code=404, detail="Task not found")

    task = task_response.data

    # Check if claimed by current user
    if task['assignee_id'] != user.user_id:
        raise HTTPException(status_code=403, detail="Can only complete tasks assigned to you")

    # Update task
    from datetime import datetime, UTC
    update_response = await db.table('tasks')\
        .update({
            'status': 'DONE',
            'outputs': data.outputs,
            'completed_at': datetime.now(UTC).isoformat(),
            'updated_at': datetime.now(UTC).isoformat()
        })\
        .eq('task_id', task_id)\
        .select('*')\
        .single()\
        .execute()

    return TaskDetail(**update_response.data)


@router.get("/task/{task_id}", response_model=TaskDetail)
async def get_task(
    task_id: str,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Get a single task by ID.

    Context7 Pattern: Path parameter with dependency injection
    Source: /fastapi/fastapi - "Path Parameters"
    """
    task = await tasks_db.get_task_by_id(db, task_id)

    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check visibility permissions
    from backend.services.authz import can_see_task
    if not can_see_task(user, task.visibility_group):
        raise HTTPException(status_code=403, detail="You do not have permission to view this task")

    return task


@router.post("/{task_id}/unclaim", response_model=TaskDetail)
async def unclaim_task(
    task_id: str,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Unclaim a task (return it to OPEN status).

    Context7 Pattern: POST for state-changing operations
    Source: /fastapi/fastapi - "Request Body"
    """
    # Get task
    task = await tasks_db.get_task_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check authorization
    if not can_unclaim_task(user, task):
        raise HTTPException(
            status_code=403,
            detail="You can only unclaim tasks assigned to you or you must be an admin"
        )

    # Update task to OPEN
    from datetime import datetime, timezone
    updated_task = await tasks_db.update_task(db, task_id, {
        "status": "OPEN",
        "assignee_id": None,
        "claimed_at": None,
        "updated_at": datetime.now(timezone.utc).isoformat()
    })

    return updated_task


@router.post("/{task_id}/reopen", response_model=TaskDetail)
async def reopen_task(
    task_id: str,
    data: TaskReopenRequest,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Reopen a completed or failed task.

    Context7 Pattern: Request body validation with Pydantic
    Source: /fastapi/fastapi - "Request Body"
    """
    # Get task
    task = await tasks_db.get_task_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check authorization
    if not can_reopen_task(user, task):
        raise HTTPException(
            status_code=403,
            detail="You can only reopen tasks you completed or you must be an admin"
        )

    # Update task back to OPEN
    from datetime import datetime, timezone
    updated_task = await tasks_db.update_task(db, task_id, {
        "status": "OPEN",
        "assignee_id": None,
        "claimed_at": None,
        "completed_at": None,
        "outputs": {},
        "updated_at": datetime.now(timezone.utc).isoformat()
    })

    # Add note with reopen reason
    await tasks_db.create_task_note(
        db,
        task_id,
        f"Task reopened: {data.reason}",
        user.user_id
    )

    return updated_task


@router.delete("/task/{task_id}", status_code=204)
async def delete_task(
    task_id: str,
    user: User = Depends(require_admin),
    db: Client = Depends(get_db)
):
    """
    Delete a task (admin only).

    Context7 Pattern: Sub-dependency for role validation
    Source: /fastapi/fastapi - "Sub-dependencies"
    """
    # Get task to verify it exists
    task = await tasks_db.get_task_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check authorization (extra check even though require_admin already validates)
    if not can_delete_task(user, task):
        raise HTTPException(status_code=403, detail="Only admins can delete tasks")

    # Soft delete
    await tasks_db.soft_delete_task(db, task_id)

    return None


@router.post("/{task_id}/notes", response_model=TaskNote, status_code=201)
async def add_task_note(
    task_id: str,
    data: TaskNoteCreate,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Add a note to a task.

    Context7 Pattern: 201 Created status for resource creation
    Source: /fastapi/fastapi - "Response Status Code"
    """
    # Verify task exists
    task = await tasks_db.get_task_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check visibility permissions
    from backend.services.authz import can_see_task
    if not can_see_task(user, task.visibility_group):
        raise HTTPException(status_code=403, detail="You do not have permission to add notes to this task")

    # Create note
    note_data = await tasks_db.create_task_note(
        db,
        task_id,
        data.content,
        user.user_id
    )

    return TaskNote(
        note_id=note_data["note_id"],
        task_id=note_data["task_id"],
        content=note_data["content"],
        created_by=note_data["author_id"],
        created_at=note_data["created_at"]
    )


@router.get("/{task_id}/notes", response_model=list[TaskNote])
async def get_task_notes(
    task_id: str,
    user: User = Depends(get_current_user),
    db: Client = Depends(get_db)
):
    """
    Get all notes for a task.

    Context7 Pattern: List response model
    Source: /fastapi/fastapi - "Response Model"
    """
    # Verify task exists and user can see it
    task = await tasks_db.get_task_by_id(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check visibility permissions
    from backend.services.authz import can_see_task
    if not can_see_task(user, task.visibility_group):
        raise HTTPException(status_code=403, detail="You do not have permission to view notes for this task")

    # Get notes
    notes_data = await tasks_db.get_task_notes(db, task_id)

    return [
        TaskNote(
            note_id=note["note_id"],
            task_id=note["task_id"],
            content=note["content"],
            created_by=note["author_id"],
            created_at=note["created_at"]
        )
        for note in notes_data
    ]
