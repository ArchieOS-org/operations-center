"""
Classification Schema (Pydantic)
Ported from llmClassifier.ts - Works with LangChain structured output

This schema is the same whether you're receiving messages from:
- Slack (current)
- SMS (future)
- Any other messaging platform

The classification logic is platform-agnostic.
LangChain will automatically use this Pydantic model for structured output validation.
"""

from pydantic import BaseModel, Field
from typing import Literal, Optional
from enum import Enum


class MessageType(str, Enum):
    """Message classification types"""
    GROUP = "GROUP"
    STRAY = "STRAY"
    INFO_REQUEST = "INFO_REQUEST"
    IGNORE = "IGNORE"


class ListingType(str, Enum):
    """Listing types (SALE or LEASE)"""
    SALE = "SALE"
    LEASE = "LEASE"


class GroupKey(str, Enum):
    """Valid group_key values for GROUP message types"""
    SALE_LISTING = "SALE_LISTING"
    LEASE_LISTING = "LEASE_LISTING"
    SALE_LEASE_LISTING = "SALE_LEASE_LISTING"
    SOLD_SALE_LEASE_LISTING = "SOLD_SALE_LEASE_LISTING"
    RELIST_LISTING = "RELIST_LISTING"
    RELIST_LISTING_DEAL_SALE_OR_LEASE = "RELIST_LISTING_DEAL_SALE_OR_LEASE"
    BUY_OR_LEASED = "BUY_OR_LEASED"
    MARKETING_AGENDA_TEMPLATE = "MARKETING_AGENDA_TEMPLATE"


class TaskKey(str, Enum):
    """Valid task_key values for STRAY message types"""
    # Sale Listings
    SALE_ACTIVE_TASKS = "SALE_ACTIVE_TASKS"
    SALE_SOLD_TASKS = "SALE_SOLD_TASKS"
    SALE_CLOSING_TASKS = "SALE_CLOSING_TASKS"

    # Lease Listings
    LEASE_ACTIVE_TASKS = "LEASE_ACTIVE_TASKS"
    LEASE_LEASED_TASKS = "LEASE_LEASED_TASKS"
    LEASE_CLOSING_TASKS = "LEASE_CLOSING_TASKS"
    LEASE_ACTIVE_TASKS_ARLYN = "LEASE_ACTIVE_TASKS_ARLYN"

    # Re-List Listings
    RELIST_LISTING_DEAL_SALE = "RELIST_LISTING_DEAL_SALE"
    RELIST_LISTING_DEAL_LEASE = "RELIST_LISTING_DEAL_LEASE"

    # Buyer Deals
    BUYER_DEAL = "BUYER_DEAL"
    BUYER_DEAL_CLOSING_TASKS = "BUYER_DEAL_CLOSING_TASKS"

    # Lease Tenant Deals
    LEASE_TENANT_DEAL = "LEASE_TENANT_DEAL"
    LEASE_TENANT_DEAL_CLOSING_TASKS = "LEASE_TENANT_DEAL_CLOSING_TASKS"

    # Pre-Con Deals
    PRECON_DEAL = "PRECON_DEAL"

    # Mutual Release
    MUTUAL_RELEASE_STEPS = "MUTUAL_RELEASE_STEPS"

    # General Ops
    OPS_MISC_TASK = "OPS_MISC_TASK"


class Listing(BaseModel):
    """Listing information"""
    type: Optional[ListingType] = None
    address: Optional[str] = None


class ClassificationV1(BaseModel):
    """
    Message classification result

    Ported from TypeScript ClassificationV1 interface
    LangChain will automatically validate against this schema
    """
    schema_version: Literal[1] = 1
    message_type: MessageType
    task_key: Optional[TaskKey] = None
    group_key: Optional[GroupKey] = None
    listing: Listing
    assignee_hint: Optional[str] = None
    due_date: Optional[str] = None  # ISO format: YYYY-MM-DD or YYYY-MM-DDThh:mm
    task_title: Optional[str] = Field(None, max_length=80)
    confidence: float = Field(ge=0, le=1)
    explanations: Optional[list[str]] = None

    def validate_keys(self) -> None:
        """
        Validate that exactly one of group_key or task_key is set
        (unless message_type is INFO_REQUEST or IGNORE)
        """
        group_present = self.group_key is not None
        task_present = self.task_key is not None

        if self.message_type in [MessageType.INFO_REQUEST, MessageType.IGNORE]:
            if group_present or task_present:
                raise ValueError(
                    f"INFO_REQUEST/IGNORE should have no keys, got group_key={self.group_key}, task_key={self.task_key}"
                )
        else:
            # GROUP or STRAY must have exactly one key
            if group_present == task_present:  # Both true or both false
                raise ValueError(
                    f"Exactly one of group_key or task_key must be set for {self.message_type}, "
                    f"got group_key={self.group_key}, task_key={self.task_key}"
                )
