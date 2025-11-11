"""
Task database operations using Supabase Python client.
Context7 Pattern: Async query functions with error handling
Source: /supabase/supabase-py - "Async queries, filtering, ordering"
"""
from typing import Optional, List
from supabase import Client
from backend.models.task import TaskDetail, TaskStatus
from fastapi import HTTPException


async def get_task_by_id(db: Client, task_id: str) -> Optional[TaskDetail]:
    """
    Get a single task by ID.

    Context7 Pattern: .from_().select().eq().execute()
    Source: /supabase/supabase-py - "Select Data from Supabase Table"

    Args:
        db: Supabase client instance
        task_id: Task identifier

    Returns:
        TaskDetail or None if not found
    """
    try:
        response = db.table("tasks").select("*").eq("task_id", task_id).is_("deleted_at", None).execute()

        if not response.data or len(response.data) == 0:
            return None

        return TaskDetail(**response.data[0])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def list_tasks_for_listing(
    db: Client,
    listing_id: str,
    status: Optional[TaskStatus] = None,
    assignee_id: Optional[str] = None,
    page: int = 1,
    limit: int = 50
) -> tuple[List[TaskDetail], int]:
    """
    List tasks for a listing with filters and pagination.

    Context7 Pattern: Chained query builder with filters
    Source: /supabase/supabase-py - "Select Specific Columns" + filtering

    Args:
        db: Supabase client
        listing_id: Listing to filter by
        status: Optional status filter
        assignee_id: Optional assignee filter
        page: Page number (1-indexed)
        limit: Results per page

    Returns:
        Tuple of (tasks list, total count)
    """
    try:
        # Build base query
        query = db.table("tasks").select("*", count="exact").eq("listing_id", listing_id).is_("deleted_at", None)

        # Apply filters
        if status:
            query = query.eq("status", status)
        if assignee_id:
            query = query.eq("assignee_id", assignee_id)

        # Apply pagination and ordering
        offset = (page - 1) * limit
        query = query.order("created_at", desc=True).range(offset, offset + limit - 1)

        # Execute query
        response = query.execute()

        # Parse results
        tasks = [TaskDetail(**task) for task in response.data]
        total = response.count if response.count is not None else 0

        return tasks, total
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def update_task(db: Client, task_id: str, updates: dict) -> TaskDetail:
    """
    Update a task with new values.

    Context7 Pattern: .update().eq().execute()
    Source: /supabase/supabase-py - "Update Data in Supabase Table"

    Args:
        db: Supabase client
        task_id: Task to update
        updates: Dictionary of fields to update

    Returns:
        Updated TaskDetail
    """
    try:
        response = db.table("tasks").update(updates).eq("task_id", task_id).execute()

        if not response.data or len(response.data) == 0:
            raise HTTPException(status_code=404, detail="Task not found")

        return TaskDetail(**response.data[0])
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def soft_delete_task(db: Client, task_id: str) -> None:
    """
    Soft delete a task by setting deleted_at timestamp.

    Context7 Pattern: .update().eq().execute() for soft deletes
    Source: /supabase/supabase-py - "Update Data"

    Args:
        db: Supabase client
        task_id: Task to delete
    """
    try:
        from datetime import datetime, timezone

        response = db.table("tasks").update({
            "deleted_at": datetime.now(timezone.utc).isoformat()
        }).eq("task_id", task_id).execute()

        if not response.data or len(response.data) == 0:
            raise HTTPException(status_code=404, detail="Task not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def create_task_note(
    db: Client,
    task_id: str,
    note_content: str,
    author_id: str
) -> dict:
    """
    Create a note for a task.

    Context7 Pattern: .insert().execute()
    Source: /supabase/supabase-py - "Insert Data"

    Args:
        db: Supabase client
        task_id: Task to add note to
        note_content: Note text
        author_id: User creating the note

    Returns:
        Created note data
    """
    try:
        from datetime import datetime, timezone
        import uuid

        note = {
            "note_id": str(uuid.uuid4()),
            "task_id": task_id,
            "content": note_content,
            "author_id": author_id,
            "created_at": datetime.now(timezone.utc).isoformat()
        }

        response = db.table("task_notes").insert(note).execute()

        if not response.data or len(response.data) == 0:
            raise HTTPException(status_code=500, detail="Failed to create note")

        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


async def get_task_notes(db: Client, task_id: str) -> List[dict]:
    """
    Get all notes for a task.

    Context7 Pattern: .select().eq().order().execute()
    Source: /supabase/supabase-py - "Select with ordering"

    Args:
        db: Supabase client
        task_id: Task to get notes for

    Returns:
        List of note dictionaries
    """
    try:
        response = db.table("task_notes").select("*").eq("task_id", task_id).order("created_at", desc=False).execute()

        return response.data if response.data else []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
