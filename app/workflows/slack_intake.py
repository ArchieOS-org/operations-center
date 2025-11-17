"""
Simplified Slack Message Intake Workflow

Processes batched messages from the queue:
1. Validate messages (skip bots)
2. Classify batched text with LLM
3. Store classification in database
4. Create entities (listing + activities OR agent_task)
5. Send Slack acknowledgment

No orchestrator, no routing - just straight processing.
"""

from typing import List, Optional
from datetime import datetime, timezone
import logging
from ulid import ULID

from app.agents import get_agent
from app.database.supabase_client import get_supabase
from app.schemas.classification import ClassificationV1
from app.queue.message_queue import QueuedMessage
from app.workflows.batched_classification import (
    batch_messages_for_classification,
    extract_all_message_timestamps,
    get_primary_thread_ts,
)
from app.workflows.entity_creation import create_entities_from_classification
from app.services.slack_client import send_acknowledgment

logger = logging.getLogger(__name__)


async def process_batched_slack_messages(
    messages: List[QueuedMessage], user_id: str, channel_id: str
) -> dict:
    """
    Main entry point for processing batched Slack messages.

    Called by the message queue timer after accumulation timeout.

    Args:
        messages: List of queued messages from same user/channel
        user_id: Slack user ID
        channel_id: Slack channel ID

    Returns:
        Dict with processing status
    """
    logger.info(
        f"Processing {len(messages)} batched message(s) from "
        f"user={user_id}, channel={channel_id}"
    )

    try:
        # Step 1: Validate messages (skip bots)
        if not await validate_messages(messages, user_id):
            return {"status": "skipped", "reason": "validation_failed"}

        # Step 2: Batch messages for classification
        batched_text = batch_messages_for_classification(messages)

        # Step 3: Classify with LLM
        classification = await classify_batched_messages(batched_text)

        if not classification:
            return {"status": "error", "reason": "classification_failed"}

        # Step 4: Store in slack_messages table
        message_id = await store_classification(
            messages=messages,
            user_id=user_id,
            channel_id=channel_id,
            classification=classification,
            batched_text=batched_text,
        )

        if not message_id:
            return {"status": "error", "reason": "storage_failed"}

        # Step 5: Create entities (listing + activities OR task)
        entity_result = await create_entities_from_classification(
            classification=classification,
            message_id=message_id,
            message_text=batched_text,
        )

        # Step 6: Send Slack acknowledgment (if entity created)
        if entity_result.get("status") == "success":
            thread_ts = get_primary_thread_ts(messages)
            await send_acknowledgment(
                classification=classification, channel=channel_id, thread_ts=thread_ts
            )

        logger.info(
            f"Batch processing complete: {entity_result.get('status')} - "
            f"{entity_result.get('entity_type', 'none')}"
        )

        return {
            "status": "success",
            "message_id": message_id,
            "entity_result": entity_result,
        }

    except Exception as e:
        logger.error(f"Batch processing failed: {str(e)}", exc_info=True)
        return {"status": "error", "reason": str(e)}


async def validate_messages(messages: List[QueuedMessage], user_id: str) -> bool:
    """
    Validate messages before processing.

    Checks:
    - Messages exist
    - User is not a bot

    Args:
        messages: List of queued messages
        user_id: Slack user ID

    Returns:
        True if validation passes, False otherwise
    """
    if not messages:
        logger.warning("No messages to validate")
        return False

    if not user_id:
        logger.warning("Missing user_id for queued messages; skipping batch")
        return False

    # Check if user is a bot (bot IDs start with 'B')
    if user_id.startswith("B"):
        logger.info(f"Skipping bot message from user={user_id}")
        return False

    # Additional validation checks could go here
    # (e.g., duplicate detection, rate limiting)

    return True


async def classify_batched_messages(batched_text: str) -> Optional[ClassificationV1]:
    """
    Classify batched message text using the MessageClassifier agent.

    Reuses existing classification logic - does NOT modify the prompt.

    Args:
        batched_text: Combined message text

    Returns:
        ClassificationV1 object or None on error
    """
    try:
        classifier = get_agent("classifier")

        if not classifier:
            logger.error(
                f"Classifier agent not found - cannot classify message "
                f"(text length: {len(batched_text)})"
            )
            return None

        result = await classifier.process({"message": batched_text})

        # Handle both shapes: {"classification": {...}} OR {...} directly
        if isinstance(result, dict):
            if "classification" in result:
                classification_dict = result["classification"]
            else:
                # Assume result itself is the classification dict
                classification_dict = result
        else:
            logger.error(
                f"Classifier returned invalid structure (not dict): "
                f"{type(result).__name__}"
            )
            return None

        # Convert dict to ClassificationV1 object
        classification = ClassificationV1(**classification_dict)

        logger.info(
            f"Classification result: {classification.message_type.value}, "
            f"confidence={classification.confidence:.2f}"
        )

        return classification

    except Exception as e:
        logger.error(f"Classification failed: {str(e)}", exc_info=True)
        return None


async def store_classification(
    messages: List[QueuedMessage],
    user_id: str,
    channel_id: str,
    classification: ClassificationV1,
    batched_text: str,
) -> Optional[str]:
    """
    Store classification in slack_messages table.

    CRITICAL: Column names MUST match database EXACTLY (snake_case).

    Args:
        messages: Original queued messages
        user_id: Slack user ID
        channel_id: Slack channel ID
        classification: Classification result
        batched_text: Combined message text

    Returns:
        message_id (ULID string) or None on error
    """
    try:
        client = get_supabase()

        message_id = str(ULID())

        # Extract timestamps for linkage
        all_timestamps = extract_all_message_timestamps(messages)
        primary_ts = messages[0].slack_ts
        thread_ts = get_primary_thread_ts(messages)

        message_data = {
            "message_id": message_id,  # PRIMARY KEY
            "slack_user_id": user_id,  # User who sent
            "slack_channel_id": channel_id,  # Channel
            "slack_ts": primary_ts,  # Primary timestamp
            "slack_thread_ts": thread_ts,  # Thread (optional)
            "message_text": batched_text,  # Combined text
            "classification": classification.model_dump(
                mode="json"
            ),  # Full JSON (mode='json' for serialization)
            "message_type": classification.message_type.value,
            "task_key": classification.task_key.value
            if classification.task_key
            else None,
            "group_key": classification.group_key.value
            if classification.group_key
            else None,
            "confidence": float(classification.confidence),
            "received_at": datetime.now(timezone.utc).isoformat(),
            "processing_status": "pending",  # Will update later
            "metadata": {"batch_size": len(messages), "all_timestamps": all_timestamps},
        }  # type: dict[str, Any]

        result = client.table("slack_messages").insert(message_data).execute()

        if result.data and len(result.data) > 0:
            logger.info(f"Stored slack_message: {message_id}")
            return message_id
        else:
            logger.error("Failed to store slack_message - no data returned")
            return None

    except Exception as e:
        logger.error(f"Error storing slack_message: {str(e)}", exc_info=True)
        return None
