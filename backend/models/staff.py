"""
Staff Pydantic models for internal team members.

Following Context7 best practices for Pydantic v2 with Field validation.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, EmailStr, field_validator
from enum import Enum


class StaffRole(str, Enum):
    """Staff roles within the organization."""
    ADMIN = "admin"
    OPERATIONS = "operations"
    MARKETING = "marketing"
    SUPPORT = "support"


class StaffStatus(str, Enum):
    """Staff account status."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"


class StaffBase(BaseModel):
    """Base staff model with common fields."""
    email: EmailStr = Field(..., description="Staff member's email address")
    name: str = Field(..., min_length=1, max_length=200, description="Full name")
    role: StaffRole = Field(..., description="Staff role in organization")
    slack_user_id: Optional[str] = Field(None, description="Slack user ID for integration")
    phone: Optional[str] = Field(None, max_length=50, description="Phone number")
    status: StaffStatus = Field(default=StaffStatus.ACTIVE, description="Account status")
    metadata: dict = Field(default_factory=dict, description="Additional flexible data")


class StaffCreate(StaffBase):
    """Model for creating a new staff member."""
    pass


class StaffUpdate(BaseModel):
    """Model for updating staff member (all fields optional)."""
    email: Optional[EmailStr] = None
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    role: Optional[StaffRole] = None
    slack_user_id: Optional[str] = None
    phone: Optional[str] = Field(None, max_length=50)
    status: Optional[StaffStatus] = None
    metadata: Optional[dict] = None


class StaffMember(StaffBase):
    """Complete staff member model (database record)."""
    staff_id: str = Field(..., description="Unique identifier (ULID)")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    deleted_at: Optional[datetime] = Field(None, description="Soft delete timestamp")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "staff_id": "01HWQK3Y9X8ZHQT2N7G4FVWXYZ",
                "email": "jane.doe@example.com",
                "name": "Jane Doe",
                "role": "operations",
                "slack_user_id": "U01234ABCD",
                "phone": "+1-555-0100",
                "status": "active",
                "metadata": {},
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z",
                "deleted_at": None
            }
        }
    }


class StaffListResponse(BaseModel):
    """Paginated list of staff members."""
    data: list[StaffMember] = Field(..., description="List of staff members")
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


class StaffSummary(BaseModel):
    """Lightweight staff summary for embedding in other responses."""
    staff_id: str
    name: str
    email: EmailStr
    role: StaffRole

    model_config = {"from_attributes": True}
