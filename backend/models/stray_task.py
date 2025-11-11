"""
Stray Task Pydantic models for realtor-specific tasks not tied to listings.

Following Context7 best practices for Pydantic v2 with Field validation.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from .listing_task import TaskStatus  # Reuse TaskStatus enum


class StrayTaskBase(BaseModel):
    """Base stray task model with common fields."""
    realtor_id: str = Field(..., description="Realtor ID this task is for")
    task_key: str = Field(..., min_length=1, max_length=100, description="Task type key from classification system")
    name: str = Field(..., min_length=1, max_length=500, description="Task name")
    description: Optional[str] = Field(None, max_length=5000, description="Task description")
    status: TaskStatus = Field(default=TaskStatus.OPEN, description="Task status")
    priority: int = Field(default=0, ge=0, le=10, description="Priority (0-10)")
    assigned_staff_id: Optional[str] = Field(None, description="Staff member assigned to help realtor")
    due_date: Optional[datetime] = Field(None, description="Task due date")
    inputs: dict = Field(default_factory=dict, description="Task input parameters")
    outputs: dict = Field(default_factory=dict, description="Task output results")


class StrayTaskCreate(StrayTaskBase):
    """Model for creating a new stray task."""
    pass


class StrayTaskUpdate(BaseModel):
    """Model for updating stray task (all fields optional)."""
    task_key: Optional[str] = Field(None, min_length=1, max_length=100)
    name: Optional[str] = Field(None, min_length=1, max_length=500)
    description: Optional[str] = Field(None, max_length=5000)
    status: Optional[TaskStatus] = None
    priority: Optional[int] = Field(None, ge=0, le=10)
    assigned_staff_id: Optional[str] = None
    due_date: Optional[datetime] = None
    inputs: Optional[dict] = None
    outputs: Optional[dict] = None


class StrayTask(StrayTaskBase):
    """Complete stray task model (database record)."""
    task_id: str = Field(..., description="Unique identifier (ULID)")
    claimed_at: Optional[datetime] = Field(None, description="When task was claimed")
    completed_at: Optional[datetime] = Field(None, description="When task was completed")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    deleted_at: Optional[datetime] = Field(None, description="Soft delete timestamp")
    deleted_by: Optional[str] = Field(None, description="User who deleted task")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "task_id": "01HWQK8B2C3DEFG5I6JKLMNOPQ",
                "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
                "task_key": "general_support",
                "name": "Update CRM records",
                "description": "Update contact information in CRM system",
                "status": "OPEN",
                "priority": 3,
                "assigned_staff_id": None,
                "due_date": "2024-02-05T17:00:00Z",
                "inputs": {},
                "outputs": {},
                "claimed_at": None,
                "completed_at": None,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z",
                "deleted_at": None,
                "deleted_by": None
            }
        }
    }


class StrayTaskListResponse(BaseModel):
    """Paginated list of stray tasks."""
    data: list[StrayTask] = Field(..., description="List of stray tasks")
    total: int = Field(..., ge=0, description="Total count")
    page: int = Field(..., ge=1, description="Current page number")
    page_size: int = Field(..., ge=1, le=100, description="Items per page")

    model_config = {
        "json_schema_extra": {
            "example": {
                "data": [],
                "total": 0,
                "page": 1,
                "page_size": 50
            }
        }
    }
