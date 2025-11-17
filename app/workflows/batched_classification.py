"""Batched message classification workflow.

Combines multiple rapid consecutive messages from the same user/channel
into a single classification input for the LLM.
"""

import logging
from typing import List
from app.queue.message_queue import QueuedMessage

logger = logging.getLogger(__name__)


def batch_messages_for_classification(messages: List[QueuedMessage]) -> str:
    """Combine multiple messages into single classification input.

    Args:
        messages: List of queued messages from same user/channel

    Returns:
        Combined text for classification, with context about message sequence
    """
    if not messages:
        return ""

    # Single message - return as-is
    if len(messages) == 1:
        return messages[0].text

    # Multiple messages - combine with timestamps for context
    combined = (
        "User sent the following messages in quick succession. "
        "Classify these as a single unit (they are related):\n\n"
    )

    for i, msg in enumerate(messages, 1):
        # Include timestamp for temporal context
        combined += f"Message {i} [{msg.slack_ts}]: {msg.text}\n"

    logger.info(f"Batched {len(messages)} messages for classification")

    return combined


def extract_all_message_timestamps(messages: List[QueuedMessage]) -> List[str]:
    """Extract all slack timestamps from batched messages.

    Args:
        messages: List of queued messages

    Returns:
        List of slack_ts values for database linkage
    """
    return [msg.slack_ts for msg in messages]


def get_primary_thread_ts(messages: List[QueuedMessage]) -> str | None:
    """Get thread timestamp if any message is in a thread.

    Args:
        messages: List of queued messages

    Returns:
        thread_ts from first threaded message, or None
    """
    for msg in messages:
        if msg.thread_ts:
            return msg.thread_ts
    return None
