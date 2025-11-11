"""
Slack Messages API router following Context7 best practices.

Provides CRUD endpoints for Slack message tracking and processing management.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Path
from ulid import ULID

from backend.models.slack_message import (
    SlackMessageCreate,
    SlackMessageUpdate,
    SlackMessage,
    SlackMessageListResponse,
    ProcessingStatus,
    CreatedTaskType
)
from backend.database import slack_messages as slack_messages_db


# Initialize router with shared configuration
router = APIRouter(
    prefix="/slack-messages",
    tags=["slack-messages"],
    responses={
        404: {"description": "Slack message not found"},
        409: {"description": "Slack message already exists"}
    }
)


@router.post(
    "/",
    response_model=SlackMessage,
    status_code=201,
    summary="Create a new Slack message record",
    description="Create a new Slack message tracking record. Message ID (ULID) is auto-generated."
)
async def create_slack_message(message_data: SlackMessageCreate) -> SlackMessage:
    """
    Create a new Slack message record.

    - **slack_user_id**: Slack user ID who sent the message
    - **slack_ts**: Slack message timestamp (must be unique)
    - **message_text**: Content of the Slack message
    - **classification**: Classification data from LangChain (JSONB)
    - **processing_status**: Processing status (defaults to 'pending')
    - **created_listing_id**: Optional ID of listing created from message
    - **created_task_id**: Optional ID of task created from message
    - **created_task_type**: Optional type of task created
    """
    # Generate ULID for new message
    message_id = str(ULID())

    try:
        return await slack_messages_db.create_slack_message(message_data, message_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create Slack message: {str(e)}"
        )


@router.get(
    "/",
    response_model=SlackMessageListResponse,
    summary="List Slack messages",
    description="Retrieve a paginated list of Slack messages with optional filters."
)
async def list_slack_messages(
    slack_user_id: Optional[str] = Query(None, description="Filter by Slack user ID"),
    processing_status: Optional[ProcessingStatus] = Query(None, description="Filter by processing status"),
    created_task_type: Optional[CreatedTaskType] = Query(None, description="Filter by created task type"),
    error_message_present: Optional[bool] = Query(None, description="Filter by presence of error message"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
) -> SlackMessageListResponse:
    """
    List all Slack messages with optional filtering and pagination.

    - **slack_user_id**: Filter by specific Slack user
    - **processing_status**: Filter by status (pending, processed, failed, skipped)
    - **created_task_type**: Filter by type of task created (listing_task, stray_task)
    - **error_message_present**: Filter by presence of error message (true/false)
    - **limit**: Maximum number of results (1-100, default 50)
    - **offset**: Pagination offset (default 0)
    """
    try:
        return await slack_messages_db.list_slack_messages(
            slack_user_id=slack_user_id,
            processing_status=processing_status,
            created_task_type=created_task_type,
            error_message_present=error_message_present,
            limit=limit,
            offset=offset
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to list Slack messages: {str(e)}"
        )


@router.get(
    "/{message_id}",
    response_model=SlackMessage,
    summary="Get Slack message by ID",
    description="Retrieve a specific Slack message by its message ID."
)
async def get_slack_message(
    message_id: str = Path(..., description="Slack message ID (ULID)")
) -> SlackMessage:
    """
    Get a specific Slack message by ID.

    - **message_id**: ULID of the Slack message
    """
    message = await slack_messages_db.get_slack_message_by_id(message_id)

    if not message:
        raise HTTPException(
            status_code=404,
            detail=f"Slack message with ID {message_id} not found"
        )

    return message


@router.get(
    "/ts/{slack_ts}",
    response_model=SlackMessage,
    summary="Get Slack message by timestamp",
    description="Retrieve a specific Slack message by its Slack timestamp (unique identifier)."
)
async def get_slack_message_by_ts(
    slack_ts: str = Path(..., description="Slack message timestamp")
) -> SlackMessage:
    """
    Get a specific Slack message by timestamp.

    - **slack_ts**: Slack message timestamp (unique identifier from Slack)
    """
    message = await slack_messages_db.get_slack_message_by_ts(slack_ts)

    if not message:
        raise HTTPException(
            status_code=404,
            detail=f"Slack message with timestamp {slack_ts} not found"
        )

    return message


@router.get(
    "/user/{slack_user_id}",
    response_model=list[SlackMessage],
    summary="Get all messages from a Slack user",
    description="Retrieve all messages from a specific Slack user."
)
async def get_slack_messages_by_user(
    slack_user_id: str = Path(..., description="Slack user ID"),
    limit: int = Query(100, ge=1, le=500, description="Maximum number of results")
) -> list[SlackMessage]:
    """
    Get all messages from a specific Slack user.

    - **slack_user_id**: Slack user ID
    - **limit**: Maximum number of messages to return (default 100, max 500)
    """
    try:
        return await slack_messages_db.get_slack_messages_by_user(slack_user_id, limit)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get messages for user: {str(e)}"
        )


@router.get(
    "/status/pending",
    response_model=list[SlackMessage],
    summary="Get all pending Slack messages",
    description="Retrieve all Slack messages awaiting processing."
)
async def get_pending_slack_messages(
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results")
) -> list[SlackMessage]:
    """
    Get all pending (unprocessed) Slack messages.

    - **limit**: Maximum number of messages to return (default 50, max 100)
    """
    try:
        return await slack_messages_db.get_pending_slack_messages(limit)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get pending messages: {str(e)}"
        )


@router.get(
    "/status/failed",
    response_model=list[SlackMessage],
    summary="Get all failed Slack messages",
    description="Retrieve all Slack messages that failed processing for retry/debugging."
)
async def get_failed_slack_messages(
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results")
) -> list[SlackMessage]:
    """
    Get all failed Slack messages for retry/debugging.

    - **limit**: Maximum number of messages to return (default 50, max 100)
    """
    try:
        return await slack_messages_db.get_failed_slack_messages(limit)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get failed messages: {str(e)}"
        )


@router.put(
    "/{message_id}",
    response_model=SlackMessage,
    summary="Update Slack message",
    description="Update an existing Slack message's information."
)
async def update_slack_message(
    message_id: str = Path(..., description="Slack message ID (ULID)"),
    message_data: SlackMessageUpdate = ...
) -> SlackMessage:
    """
    Update a Slack message's information.

    - **message_id**: ULID of the Slack message
    - **message_data**: Fields to update (all optional)

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    # Check if message exists
    existing = await slack_messages_db.get_slack_message_by_id(message_id)
    if not existing:
        raise HTTPException(
            status_code=404,
            detail=f"Slack message with ID {message_id} not found"
        )

    try:
        return await slack_messages_db.update_slack_message(message_id, message_data)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update Slack message: {str(e)}"
        )


@router.post(
    "/{message_id}/mark-processed",
    response_model=SlackMessage,
    summary="Mark Slack message as processed",
    description="Mark a Slack message as successfully processed and record what was created."
)
async def mark_slack_message_processed(
    message_id: str = Path(..., description="Slack message ID (ULID)"),
    created_listing_id: Optional[str] = Query(None, description="ID of listing created"),
    created_task_id: Optional[str] = Query(None, description="ID of task created"),
    created_task_type: Optional[CreatedTaskType] = Query(None, description="Type of task created")
) -> SlackMessage:
    """
    Mark a Slack message as processed.

    - **message_id**: ULID of the Slack message
    - **created_listing_id**: Optional ID of listing that was created
    - **created_task_id**: Optional ID of task that was created
    - **created_task_type**: Optional type of task (listing_task or stray_task)
    """
    try:
        return await slack_messages_db.mark_slack_message_processed(
            message_id,
            created_listing_id,
            created_task_id,
            created_task_type
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to mark message as processed: {str(e)}"
        )


@router.post(
    "/{message_id}/mark-failed",
    response_model=SlackMessage,
    summary="Mark Slack message as failed",
    description="Mark a Slack message as failed with error details."
)
async def mark_slack_message_failed(
    message_id: str = Path(..., description="Slack message ID (ULID)"),
    error_message: str = Query(..., description="Error message describing what went wrong")
) -> SlackMessage:
    """
    Mark a Slack message as failed.

    - **message_id**: ULID of the Slack message
    - **error_message**: Description of the error that occurred
    """
    try:
        return await slack_messages_db.mark_slack_message_failed(message_id, error_message)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to mark message as failed: {str(e)}"
        )


@router.delete(
    "/{message_id}",
    status_code=204,
    summary="Delete Slack message",
    description="Soft delete a Slack message (sets deleted_at timestamp)."
)
async def delete_slack_message(
    message_id: str = Path(..., description="Slack message ID (ULID)")
):
    """
    Soft delete a Slack message.

    - **message_id**: ULID of the Slack message

    Note: This is a soft delete. The message record remains in the database
    with deleted_at timestamp set, but will not appear in queries.
    """
    deleted = await slack_messages_db.soft_delete_slack_message(message_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail=f"Slack message with ID {message_id} not found"
        )

    return None
