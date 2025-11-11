"""
Common Pydantic models shared across the API.
Context7 Pattern: BaseModel with Field() constraints
Source: /pydantic/pydantic docs
"""
from pydantic import BaseModel, Field


class PaginationResponse(BaseModel):
    """
    Pagination metadata for list responses.

    Context7 Pattern: Field() with constraints (ge, le)
    Source: /pydantic/pydantic - "Configure Pydantic Model Fields"
    """
    page: int = Field(..., ge=1, description="Current page number")
    limit: int = Field(..., ge=1, le=100, description="Items per page")
    total: int = Field(..., ge=0, description="Total number of items")
    total_pages: int = Field(..., ge=1, description="Total number of pages")
    has_more: bool = Field(..., description="Whether there are more pages")


class ErrorResponse(BaseModel):
    """Standard error response format."""
    error: str = Field(..., description="Error message")
    detail: str | None = Field(None, description="Detailed error information")
