"""Smart message queue with batching for Slack messages.

Accumulates rapid consecutive messages from the same user/channel,
then processes them as a single batch after a timeout period.
"""

import asyncio
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class QueuedMessage:
    """Single message in the queue."""

    event: dict
    received_at: datetime
    text: str
    slack_ts: str
    thread_ts: Optional[str] = None


@dataclass
class MessageQueue:
    """Queue for batching messages from same user/channel."""

    queue_key: str  # Format: "user_id:channel_id"
    messages: List[QueuedMessage] = field(default_factory=list)
    timer: Optional[asyncio.Task] = None
    status: str = "accumulating"  # accumulating | processing
    user_id: str = ""
    channel_id: str = ""


# Global queue storage (in-memory)
# Key format: "user_id:channel_id"
_active_queues: Dict[str, MessageQueue] = {}

# Configuration
BATCH_TIMEOUT_SECONDS = 2.0  # Wait 2 seconds for more messages
MAX_BATCH_SIZE = 10  # Max messages per batch


def _make_queue_key(user_id: str, channel_id: str) -> str:
    """Create composite key for queue identification."""
    return f"{user_id}:{channel_id}"


async def enqueue_message(
    user_id: str,
    channel_id: str,
    event: dict,
    processor_callback: Callable[..., Any],
) -> None:
    """Add message to queue and manage batching timer.

    Args:
        user_id: Slack user ID
        channel_id: Slack channel ID
        event: Full Slack event dict
        processor_callback: Async function to call when batch is ready
            Signature: async def process(messages: List[dict], user_id: str, channel_id: str)
    """
    queue_key = _make_queue_key(user_id, channel_id)

    # Create queued message
    queued_msg = QueuedMessage(
        event=event,
        received_at=datetime.now(timezone.utc),
        text=event.get("text", ""),
        slack_ts=event.get("ts", ""),
        thread_ts=event.get("thread_ts"),
    )

    # Get or create queue
    if (
        queue_key not in _active_queues
        or _active_queues[queue_key].status == "processing"
    ):
        # Create new queue
        queue = MessageQueue(
            queue_key=queue_key,
            user_id=user_id,
            channel_id=channel_id,
            messages=[queued_msg],
        )
        _active_queues[queue_key] = queue

        logger.info(f"Created new queue for {queue_key}, message count: 1")
    else:
        # Add to existing queue
        queue = _active_queues[queue_key]

        # Cancel existing timer (we'll create a new one)
        if queue.timer and not queue.timer.done():
            queue.timer.cancel()
            logger.debug(f"Cancelled timer for {queue_key}, resetting")

        # Add message
        queue.messages.append(queued_msg)

        logger.info(
            f"Added to existing queue {queue_key}, message count: {len(queue.messages)}"
        )

        # Check if we hit max batch size
        if len(queue.messages) >= MAX_BATCH_SIZE:
            logger.info(
                f"Queue {queue_key} hit max size ({MAX_BATCH_SIZE}), "
                f"processing immediately"
            )
            await _process_queue(queue_key, processor_callback)
            return

    # Start new timer
    queue.timer = asyncio.create_task(
        _batch_timer(queue_key, processor_callback, BATCH_TIMEOUT_SECONDS)
    )

    logger.debug(f"Started {BATCH_TIMEOUT_SECONDS}s timer for {queue_key}")


async def _batch_timer(
    queue_key: str, processor_callback: Callable[..., Any], delay: float
) -> None:
    """Wait for timeout, then process the queue.

    Args:
        queue_key: Queue identifier
        processor_callback: Function to call with batched messages
        delay: Seconds to wait before processing
    """
    try:
        await asyncio.sleep(delay)
        logger.info(f"Timer expired for {queue_key}, processing batch")
        await _process_queue(queue_key, processor_callback)
    except asyncio.CancelledError:
        logger.debug(f"Timer cancelled for {queue_key}")
        # This is normal when new messages arrive


async def _process_queue(
    queue_key: str, processor_callback: Callable[..., Any]
) -> None:
    """Process all messages in the queue as a batch.

    Args:
        queue_key: Queue identifier
        processor_callback: Async function to call with batch
    """
    if queue_key not in _active_queues:
        logger.warning(f"Queue {queue_key} not found for processing")
        return

    queue = _active_queues[queue_key]

    # Mark as processing
    queue.status = "processing"

    # Extract messages
    messages = queue.messages.copy()
    user_id = queue.user_id
    channel_id = queue.channel_id

    logger.info(f"Processing batch for {queue_key}: {len(messages)} message(s)")

    try:
        # Call the processor with batched messages
        await processor_callback(
            messages=messages, user_id=user_id, channel_id=channel_id
        )

        logger.info(f"Batch processed successfully for {queue_key}")
    except Exception as e:
        logger.error(f"Error processing batch for {queue_key}: {e}", exc_info=True)
    finally:
        # Clean up queue
        if queue_key in _active_queues:
            del _active_queues[queue_key]
            logger.debug(f"Removed queue {queue_key}")


def get_queue(user_id: str, channel_id: str) -> Optional[MessageQueue]:
    """Get queue for debugging/monitoring.

    Args:
        user_id: Slack user ID
        channel_id: Slack channel ID

    Returns:
        MessageQueue if exists, None otherwise
    """
    queue_key = _make_queue_key(user_id, channel_id)
    return _active_queues.get(queue_key)


def get_all_queues() -> Dict[str, MessageQueue]:
    """Get all active queues for monitoring.

    Returns:
        Dict of queue_key -> MessageQueue
    """
    return _active_queues.copy()


def get_queue_stats() -> dict:
    """Get statistics about active queues.

    Returns:
        Dict with queue statistics
    """
    total_queues = len(_active_queues)
    total_messages = sum(len(q.messages) for q in _active_queues.values())
    accumulating = sum(1 for q in _active_queues.values() if q.status == "accumulating")
    processing = sum(1 for q in _active_queues.values() if q.status == "processing")

    return {
        "total_queues": total_queues,
        "total_messages": total_messages,
        "accumulating": accumulating,
        "processing": processing,
        "queues": [
            {"key": q.queue_key, "messages": len(q.messages), "status": q.status}
            for q in _active_queues.values()
        ],
    }
