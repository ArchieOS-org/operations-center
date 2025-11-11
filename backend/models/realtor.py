"""
Realtor Pydantic models for real estate agents and brokers.

Following Context7 best practices for Pydantic v2 with Field validation.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, EmailStr
from enum import Enum


class RealtorStatus(str, Enum):
    """Realtor account status."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING = "pending"


class RealtorBase(BaseModel):
    """Base realtor model with common fields."""
    email: EmailStr = Field(..., description="Realtor's email address")
    name: str = Field(..., min_length=1, max_length=200, description="Full name")
    phone: Optional[str] = Field(None, max_length=50, description="Phone number")
    license_number: Optional[str] = Field(None, max_length=100, description="Real estate license number")
    brokerage: Optional[str] = Field(None, max_length=200, description="Brokerage firm name")
    slack_user_id: Optional[str] = Field(None, description="Slack user ID for integration")
    territories: list[str] = Field(default_factory=list, description="Geographic regions covered")
    status: RealtorStatus = Field(default=RealtorStatus.PENDING, description="Account status")
    metadata: dict = Field(default_factory=dict, description="Additional flexible data")


class RealtorCreate(RealtorBase):
    """Model for creating a new realtor."""
    pass


class RealtorUpdate(BaseModel):
    """Model for updating realtor (all fields optional)."""
    email: Optional[EmailStr] = None
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    phone: Optional[str] = Field(None, max_length=50)
    license_number: Optional[str] = Field(None, max_length=100)
    brokerage: Optional[str] = Field(None, max_length=200)
    slack_user_id: Optional[str] = None
    territories: Optional[list[str]] = None
    status: Optional[RealtorStatus] = None
    metadata: Optional[dict] = None


class Realtor(RealtorBase):
    """Complete realtor model (database record)."""
    realtor_id: str = Field(..., description="Unique identifier (ULID)")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    deleted_at: Optional[datetime] = Field(None, description="Soft delete timestamp")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "realtor_id": "01HWQK5Z8Y9ABCD3F4G5HVWXYZ",
                "email": "john.agent@realty.com",
                "name": "John Agent",
                "phone": "+1-555-0200",
                "license_number": "CA-DRE-01234567",
                "brokerage": "Premier Realty Group",
                "slack_user_id": "U56789EFGH",
                "territories": ["San Francisco", "Oakland", "Berkeley"],
                "status": "active",
                "metadata": {},
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z",
                "deleted_at": None
            }
        }
    }


class RealtorListResponse(BaseModel):
    """Paginated list of realtors."""
    data: list[Realtor] = Field(..., description="List of realtors")
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


class RealtorSummary(BaseModel):
    """Lightweight realtor summary for embedding in other responses."""
    realtor_id: str
    name: str
    email: EmailStr
    phone: Optional[str] = None
    brokerage: Optional[str] = None

    model_config = {"from_attributes": True}
