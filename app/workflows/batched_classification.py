"""Batched message classification workflow.

Combines multiple rapid consecutive messages from the same user/channel
into a single classification input for the LLM.
"""

import logging
from typing import List
from app.queue.message_queue import QueuedMessage

logger = logging.getLogger(__name__)


def batch_messages_for_classification(messages: List[QueuedMessage]) -> str:
    """
    Create a single classification input by batching consecutive messages from the same user/channel.
    
    If `messages` is empty, returns an empty string. If `messages` contains exactly one item, returns that message's text unchanged. If `messages` contains multiple items, returns a combined string starting with a header indicating the messages should be classified as a single unit, followed by each message on its own line in the form "Message i [timestamp]: text".
    
    Parameters:
        messages (List[QueuedMessage]): Ordered list of queued messages (expected to be from the same user/channel and in chronological order).
    
    Returns:
        str: The combined classification input: empty string for no messages, the single message text for one message, or a header plus enumerated messages with their Slack timestamps for multiple messages.
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
    """
    Return a list of Slack message timestamps extracted from the input messages.
    
    Parameters:
        messages (List[QueuedMessage]): Queued messages to extract timestamps from.
    
    Returns:
        List[str]: The `slack_ts` value from each message, in input order.
    """
    return [msg.slack_ts for msg in messages]


def get_primary_thread_ts(messages: List[QueuedMessage]) -> str | None:
    """
    Return the thread timestamp from the first message that belongs to a thread.
    
    Parameters:
        messages (List[QueuedMessage]): Messages to scan for a thread timestamp.
    
    Returns:
        str | None: The `thread_ts` of the first message with a thread timestamp, or `None` if no threaded message is found.
    """
    for msg in messages:
        if msg.thread_ts:
            return msg.thread_ts
    return None