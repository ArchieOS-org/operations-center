"""
Task Pydantic models for API request/response validation.
Context7 Pattern: BaseModel with Field() validation and Literal types
Source: /pydantic/pydantic docs
"""
from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime
from backend.models.common import PaginationResponse


class TaskBase(BaseModel):
    """Base task model with common fields."""
    name: str = Field(..., min_length=1, max_length=255, description="Task name")
    task_category: str = Field(..., description="Task category (ADMIN, MARKETING, etc.)")
    priority: int = Field(default=0, ge=0, le=10, description="Task priority (0-10)")
    visibility_group: Literal["BOTH", "AGENT", "MARKETING"] = Field(
        default="BOTH",
        description="Who can see this task"
    )


class TaskDetail(TaskBase):
    """
    Complete task model with all fields.

    Context7 Pattern: Pydantic model with Literal types for enums
    Source: /pydantic/pydantic - "Define and validate Pydantic data model"
    """
    task_id: str = Field(..., description="Unique task identifier (ULID)")
    listing_id: str = Field(..., description="Associated listing ID")
    status: Literal["OPEN", "CLAIMED", "DONE", "FAILED"] = Field(
        ..., 
        description="Task status"
    )
    assignee_id: Optional[str] = Field(None, description="Assigned user ID")
    due_date: Optional[datetime] = Field(None, description="Task due date")
    is_stray: bool = Field(default=False, description="Whether this is a stray task")
    agent_id: Optional[str] = Field(None, description="Agent ID for stray tasks")
    inputs: dict = Field(default_factory=dict, description="Task input parameters")
    outputs: dict = Field(default_factory=dict, description="Task output results")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    claimed_at: Optional[datetime] = Field(None, description="Claim timestamp")
    completed_at: Optional[datetime] = Field(None, description="Completion timestamp")

    class Config:
        """Pydantic configuration."""
        from_attributes = True  # For ORM compatibility
        json_schema_extra = {
            "example": {
                "task_id": "01HX7K6T9QZJWX8Y4M3N2P1R0S",
                "listing_id": "01HX7K5T8PYJVW7X3L2M1N0P9R",
                "name": "Review listing photos",
                "task_category": "MARKETING",
                "status": "OPEN",
                "priority": 5,
                "visibility_group": "BOTH",
                "is_stray": False,
                "created_at": "2024-01-15T10:00:00Z",
                "updated_at": "2024-01-15T10:00:00Z"
            }
        }


class TaskListResponse(BaseModel):
    """
    Response model for task list endpoints.

    Context7 Pattern: Composed models for structured responses
    """
    tasks: list[TaskDetail] = Field(..., description="List of tasks")
    pagination: PaginationResponse = Field(..., description="Pagination metadata")


class TaskClaimRequest(BaseModel):
    """Request body for claiming a task."""
    notes: Optional[str] = Field(None, max_length=1000, description="Optional notes")


class TaskCompleteRequest(BaseModel):
    """Request body for completing a task."""
    outputs: dict = Field(default_factory=dict, description="Task output results")
    notes: Optional[str] = Field(None, max_length=1000, description="Optional notes")


class TaskReopenRequest(BaseModel):
    """Request body for reopening a task."""
    reason: str = Field(..., min_length=1, max_length=1000, description="Reason for reopening")


class TaskNoteCreate(BaseModel):
    """Request body for adding a note to a task."""
    content: str = Field(..., min_length=1, max_length=5000, description="Note content")


class TaskNote(BaseModel):
    """Task note model."""
    note_id: str = Field(..., description="Note identifier")
    task_id: str = Field(..., description="Associated task ID")
    content: str = Field(..., description="Note content")
    created_by: str = Field(..., description="User ID who created the note")
    created_at: datetime = Field(..., description="Creation timestamp")

    class Config:
        from_attributes = True
