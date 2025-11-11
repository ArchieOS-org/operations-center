"""
Listing Task Pydantic models for property-specific tasks.

Following Context7 best practices for Pydantic v2 with Field validation.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from enum import Enum


class TaskCategory(str, Enum):
    """Task categories."""
    ADMIN = "ADMIN"
    MARKETING = "MARKETING"
    PHOTO = "PHOTO"
    STAGING = "STAGING"
    INSPECTION = "INSPECTION"
    OTHER = "OTHER"


class TaskStatus(str, Enum):
    """Task status values."""
    OPEN = "OPEN"
    CLAIMED = "CLAIMED"
    IN_PROGRESS = "IN_PROGRESS"
    DONE = "DONE"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class VisibilityGroup(str, Enum):
    """Task visibility groups."""
    BOTH = "BOTH"
    AGENT = "AGENT"
    MARKETING = "MARKETING"


class ListingTaskBase(BaseModel):
    """Base listing task model with common fields."""
    listing_id: str = Field(..., description="Listing ID this task is for")
    realtor_id: Optional[str] = Field(None, description="Realtor for this listing")
    name: str = Field(..., min_length=1, max_length=500, description="Task name")
    description: Optional[str] = Field(None, max_length=5000, description="Task description")
    task_category: TaskCategory = Field(..., description="Task category")
    status: TaskStatus = Field(default=TaskStatus.OPEN, description="Task status")
    priority: int = Field(default=0, ge=0, le=10, description="Priority (0-10)")
    visibility_group: VisibilityGroup = Field(default=VisibilityGroup.BOTH, description="Who can see this task")
    assigned_staff_id: Optional[str] = Field(None, description="Staff member assigned to this task")
    due_date: Optional[datetime] = Field(None, description="Task due date")
    inputs: dict = Field(default_factory=dict, description="Task input parameters")
    outputs: dict = Field(default_factory=dict, description="Task output results")


class ListingTaskCreate(ListingTaskBase):
    """Model for creating a new listing task."""
    pass


class ListingTaskUpdate(BaseModel):
    """Model for updating listing task (all fields optional)."""
    name: Optional[str] = Field(None, min_length=1, max_length=500)
    description: Optional[str] = Field(None, max_length=5000)
    task_category: Optional[TaskCategory] = None
    status: Optional[TaskStatus] = None
    priority: Optional[int] = Field(None, ge=0, le=10)
    visibility_group: Optional[VisibilityGroup] = None
    assigned_staff_id: Optional[str] = None
    due_date: Optional[datetime] = None
    inputs: Optional[dict] = None
    outputs: Optional[dict] = None


class ListingTask(ListingTaskBase):
    """Complete listing task model (database record)."""
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
                "task_id": "01HWQK7A1B2CDEF4H5JKLMNOP",
                "listing_id": "01HWQK6Z9X8ABCD3F4G5HVWXY",
                "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
                "name": "Schedule professional photography",
                "description": "Coordinate with photographer for property photos",
                "task_category": "PHOTO",
                "status": "OPEN",
                "priority": 5,
                "visibility_group": "BOTH",
                "assigned_staff_id": None,
                "due_date": "2024-02-01T14:00:00Z",
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


class ListingTaskListResponse(BaseModel):
    """Paginated list of listing tasks."""
    data: list[ListingTask] = Field(..., description="List of listing tasks")
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
