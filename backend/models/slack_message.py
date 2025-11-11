"""
Slack Message Pydantic models for message tracking and classification.

Following Context7 best practices for Pydantic v2 with Field validation.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from enum import Enum
from decimal import Decimal


class ProcessingStatus(str, Enum):
    """Slack message processing status."""
    PENDING = "pending"
    PROCESSED = "processed"
    FAILED = "failed"
    SKIPPED = "skipped"


class CreatedTaskType(str, Enum):
    """Type of task created from Slack message."""
    LISTING_TASK = "listing_task"
    STRAY_TASK = "stray_task"


class SlackMessageBase(BaseModel):
    """Base Slack message model with common fields."""
    slack_user_id: str = Field(..., description="Slack user ID who sent the message")
    slack_channel_id: str = Field(..., description="Slack channel ID where message was sent")
    slack_ts: str = Field(..., description="Slack message timestamp (unique ID)")
    slack_thread_ts: Optional[str] = Field(None, description="Thread timestamp if in thread")
    message_text: str = Field(..., description="Message content")
    classification: dict = Field(..., description="Full classification result from LangChain (JSON)")
    message_type: str = Field(..., description="Classified message type")
    task_key: Optional[str] = Field(None, description="Task key from TaskKey enum if applicable")
    group_key: Optional[str] = Field(None, description="Group key for task categorization")
    confidence: Optional[Decimal] = Field(None, ge=0, le=1, decimal_places=4, description="Classification confidence (0-1)")
    created_listing_id: Optional[str] = Field(None, description="Listing created from this message")
    created_task_id: Optional[str] = Field(None, description="Task ID created from this message")
    created_task_type: Optional[CreatedTaskType] = Field(None, description="Type of task created")
    processing_status: ProcessingStatus = Field(default=ProcessingStatus.PENDING, description="Processing state")
    error_message: Optional[str] = Field(None, max_length=5000, description="Error message if processing failed")
    metadata: dict = Field(default_factory=dict, description="Additional flexible data")


class SlackMessageCreate(SlackMessageBase):
    """Model for creating a new Slack message record."""
    pass


class SlackMessage(SlackMessageBase):
    """Complete Slack message model (database record)."""
    message_id: str = Field(..., description="Unique identifier (ULID)")
    received_at: datetime = Field(..., description="When message was received")
    processed_at: Optional[datetime] = Field(None, description="When message was processed")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "message_id": "01HWQK9C3D4EFGH6J7KLMNOPQR",
                "slack_user_id": "U56789EFGH",
                "slack_channel_id": "C0123456789",
                "slack_ts": "1705317000.123456",
                "slack_thread_ts": None,
                "message_text": "New listing at 123 Main St, San Francisco",
                "classification": {
                    "type": "new_listing",
                    "confidence": 0.95,
                    "extracted_data": {}
                },
                "message_type": "new_listing",
                "task_key": None,
                "group_key": None,
                "confidence": "0.9500",
                "created_listing_id": "01HWQK6Z9X8ABCD3F4G5HVWXY",
                "created_task_id": None,
                "created_task_type": None,
                "processing_status": "processed",
                "error_message": None,
                "metadata": {},
                "received_at": "2024-01-15T10:30:00Z",
                "processed_at": "2024-01-15T10:30:01Z"
            }
        }
    }


class SlackMessageListResponse(BaseModel):
    """Paginated list of Slack messages."""
    data: list[SlackMessage] = Field(..., description="List of Slack messages")
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
