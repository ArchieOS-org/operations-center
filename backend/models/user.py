"""
User Pydantic models.
Context7 Pattern: BaseModel with Field() validation
Source: /pydantic/pydantic docs
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class User(BaseModel):
    """
    User model representing an authenticated user.

    Context7 Pattern: Pydantic BaseModel with type hints
    Source: /pydantic/pydantic - "Define and validate a Pydantic data model"
    """
    user_id: str = Field(..., description="Unique user identifier")
    email: Optional[EmailStr] = Field(None, description="User email address")
    name: Optional[str] = Field(None, description="User full name")
    tenant_id: Optional[str] = Field(None, description="Tenant/organization ID")
    provider: str = Field(..., description="Auth provider (cognito, google, debug)")
    roles: list[str] = Field(default_factory=list, description="User roles (ADMIN_OPS, etc.)")
    groups: list[str] = Field(default_factory=list, description="User groups (AGENT, MARKETING)")

    class Config:
        """Pydantic configuration."""
        from_attributes = True  # For ORM compatibility
