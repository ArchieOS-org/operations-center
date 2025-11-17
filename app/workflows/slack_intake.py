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
from app.workflows.batched_classification import batch_messages_for_classification, extract_all_message_timestamps, get_primary_thread_ts
from app.workflows.entity_creation import create_entities_from_classification
from app.services.slack_client import send_acknowledgment

logger = logging.getLogger(__name__)


async def process_batched_slack_messages(
    messages: List[QueuedMessage],
    user_id: str,
    channel_id: str
) -> dict:
    """
    Process a batch of Slack messages: validate, classify, persist the classification, create related entities, and send a Slack acknowledgment when appropriate.
    
    Parameters:
        messages (List[QueuedMessage]): Queued messages from the same Slack user/channel to process as a single batch.
        user_id (str): Slack user ID associated with the messages.
        channel_id (str): Slack channel ID where the messages were posted.
    
    Returns:
        dict: A summary of processing outcome. Typical shapes:
            - {"status": "success", "message_id": "<ulid>", "entity_result": {...}}
            - {"status": "skipped", "reason": "<validation_reason>"}
            - {"status": "error", "reason": "<error_message>"}
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
            batched_text=batched_text
        )

        if not message_id:
            return {"status": "error", "reason": "storage_failed"}

        # Step 5: Create entities (listing + activities OR task)
        entity_result = await create_entities_from_classification(
            classification=classification,
            message_id=message_id,
            message_text=batched_text
        )

        # Step 6: Send Slack acknowledgment (if entity created)
        if entity_result.get("status") == "success":
            thread_ts = get_primary_thread_ts(messages)
            await send_acknowledgment(
                classification=classification,
                channel=channel_id,
                thread_ts=thread_ts
            )

        logger.info(
            f"Batch processing complete: {entity_result.get('status')} - "
            f"{entity_result.get('entity_type', 'none')}"
        )

        return {
            "status": "success",
            "message_id": message_id,
            "entity_result": entity_result
        }

    except Exception as e:
        logger.error(f"Batch processing failed: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "reason": str(e)
        }


async def validate_messages(
    messages: List[QueuedMessage],
    user_id: str
) -> bool:
    """
    Validate a batch of queued Slack messages for processing.
    
    Performs basic checks to ensure there are messages and that the sender is not a bot (Slack bot IDs start with 'B').
    
    Parameters:
        messages (List[QueuedMessage]): The queued Slack messages to validate.
        user_id (str): Slack user ID of the message sender.
    
    Returns:
        True if the batch should be processed, False otherwise.
    """
    if not messages:
        logger.warning("No messages to validate")
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
    Classify combined Slack message text and return a ClassificationV1 describing the determined type and confidence.
    
    Parameters:
        batched_text (str): Combined text from a batch of Slack messages to classify.
    
    Returns:
        ClassificationV1 or None: A ClassificationV1 instance containing classification details (e.g., message_type, confidence) on success, `None` if classification failed.
    """
    try:
        classifier = get_agent("classifier")

        result = await classifier.process({
            "message": batched_text
        })

        classification_dict = result.get("classification")

        if not classification_dict:
            logger.error("Classifier returned no classification")
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
    batched_text: str
) -> Optional[str]:
    """
    Persist a classification and associated batch metadata to the slack_messages table and return the created message ULID.
    
    Parameters:
        messages (List[QueuedMessage]): Original queued Slack messages that comprise the batch.
        user_id (str): Slack user ID of the message sender.
        channel_id (str): Slack channel ID where the messages were posted.
        classification (ClassificationV1): Classification result to store (serialized as JSON).
        batched_text (str): Combined text of the batched messages to store as message_text.
    
    Returns:
        Optional[str]: The generated message_id (ULID string) if the database insert succeeded, or `None` on failure.
    """
    try:
        client = get_supabase()

        message_id = str(ULID())

        # Extract timestamps for linkage
        all_timestamps = extract_all_message_timestamps(messages)
        primary_ts = messages[0].slack_ts
        thread_ts = get_primary_thread_ts(messages)

        message_data = {
            "message_id": message_id,                                    # PRIMARY KEY
            "slack_user_id": user_id,                                    # User who sent
            "slack_channel_id": channel_id,                              # Channel
            "slack_ts": primary_ts,                                      # Primary timestamp
            "slack_thread_ts": thread_ts,                                # Thread (optional)
            "message_text": batched_text,                                # Combined text
            "classification": classification.model_dump(),               # Full JSON
            "message_type": classification.message_type.value,
            "task_key": classification.task_key.value if classification.task_key else None,
            "group_key": classification.group_key.value if classification.group_key else None,
            "confidence": float(classification.confidence),
            "received_at": datetime.now(timezone.utc).isoformat(),
            "processing_status": "pending",                              # Will update later
            "metadata": {
                "batch_size": len(messages),
                "all_timestamps": all_timestamps
            }
        }

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