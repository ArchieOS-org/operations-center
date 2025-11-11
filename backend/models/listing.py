"""
Listing Pydantic models for API request/response validation.
Context7 Pattern: BaseModel with Field() validation and Literal types
Source: /pydantic/pydantic docs
"""
from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime
from backend.models.common import PaginationResponse


class ListingBase(BaseModel):
    """Base listing model with common fields."""
    address: str = Field(..., min_length=1, max_length=500, description="Property address")
    status: Literal["new", "in_progress", "completed"] = Field(
        default="new",
        description="Listing status"
    )
    type: Optional[str] = Field(None, description="Listing type")


class ListingDetail(ListingBase):
    """
    Complete listing model with all fields.

    Context7 Pattern: Pydantic model with Literal types for enums
    Source: /pydantic/pydantic - "Define and validate Pydantic data model"
    """
    id: str = Field(..., description="Unique listing identifier (ULID)")
    assignee: Optional[str] = Field(None, description="Assigned user ID")
    agent_id: Optional[str] = Field(None, description="Agent ID")
    due_date: Optional[datetime] = Field(None, description="Listing due date")
    progress: Optional[float] = Field(None, ge=0, le=100, description="Progress percentage")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    class Config:
        """Pydantic configuration."""
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": "01HX7K6T9QZJWX8Y4M3N2P1R0S",
                "address": "123 Main St, San Francisco, CA 94105",
                "status": "new",
                "assignee": None,
                "agent_id": "agent-123",
                "due_date": "2024-12-31T23:59:59Z",
                "progress": 25.5,
                "type": "residential",
                "created_at": "2024-01-15T10:00:00Z",
                "updated_at": "2024-01-15T10:00:00Z"
            }
        }


class ListingPropertyDetails(BaseModel):
    """Property details for a listing."""
    property_type: Optional[str] = Field(None, description="Property type (residential, commercial, etc.)")
    bedrooms: int = Field(default=0, ge=0, description="Number of bedrooms")
    bathrooms: float = Field(default=0, ge=0, description="Number of bathrooms")
    sqft: int = Field(default=0, ge=0, description="Square footage")
    year_built: int = Field(default=0, ge=0, description="Year the property was built")
    list_price: float = Field(default=0, ge=0, description="Listing price in USD")
    notes: Optional[str] = Field(None, description="Additional property notes")

    class Config:
        from_attributes = True


class ListingHistoryEvent(BaseModel):
    """History event for a listing."""
    id: str = Field(..., description="Event ID")
    action: str = Field(..., description="Action performed")
    performed_by: Optional[str] = Field(None, description="User who performed action")
    timestamp: datetime = Field(..., description="When the action occurred")
    changes: Optional[dict] = Field(None, description="Changes made")
    content: Optional[str] = Field(None, description="Additional event content")

    class Config:
        from_attributes = True


class ListingTaskSummary(BaseModel):
    """Simplified task model for listing details."""
    id: str = Field(..., description="Task ID")
    title: str = Field(..., description="Task title")
    status: str = Field(..., description="Task status")
    assignee: Optional[str] = Field(None, description="Task assignee")
    task_category: Optional[str] = Field(None, description="Task category")

    class Config:
        from_attributes = True


class ListingNote(BaseModel):
    """Note attached to a listing."""
    id: str = Field(..., description="Note ID")
    content: str = Field(..., description="Note content")
    type: str = Field(..., description="Note type")
    created_by: Optional[str] = Field(None, description="User who created the note")
    created_at: datetime = Field(..., description="Creation timestamp")

    class Config:
        from_attributes = True


class ListingDetailsResponse(BaseModel):
    """
    Full listing details response with related data.

    Context7 Pattern: Composed models for structured responses
    Source: /pydantic/pydantic - "Nested models"
    """
    listing: ListingDetail = Field(..., description="Listing information")
    details: ListingPropertyDetails = Field(..., description="Property details")
    history: list[ListingHistoryEvent] = Field(default_factory=list, description="History events")
    tasks: list[ListingTaskSummary] = Field(default_factory=list, description="Associated tasks")
    notes: list[ListingNote] = Field(default_factory=list, description="Listing notes")

    class Config:
        from_attributes = True


class ListingListResponse(BaseModel):
    """
    Response model for listing list endpoints.

    Context7 Pattern: Composed models for structured responses
    """
    listings: list[ListingDetail] = Field(..., description="List of listings")
    pagination: PaginationResponse = Field(..., description="Pagination metadata")
