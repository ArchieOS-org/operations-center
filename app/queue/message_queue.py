"""Smart message queue with batching for Slack messages.

Accumulates rapid consecutive messages from the same user/channel,
then processes them as a single batch after a timeout period.
"""

import asyncio
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional
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
    """
    Produce a composite key identifying a user's queue in a channel.
    
    Returns:
        queue_key (str): Composite key in the format "user_id:channel_id".
    """
    return f"{user_id}:{channel_id}"


async def enqueue_message(
    user_id: str,
    channel_id: str,
    event: dict,
    processor_callback: callable
) -> None:
    """
    Enqueue a Slack event into the per-user/channel batching queue and schedule batch processing.
    
    Parameters:
        user_id (str): Slack user ID that identifies the queue owner.
        channel_id (str): Slack channel ID that identifies the queue target.
        event (dict): Full Slack event payload for the message.
        processor_callback (callable): Async callable invoked when a batch is ready.
            It is called as: await processor_callback(messages, user_id=user_id, channel_id=channel_id)
            where `messages` is a list of QueuedMessage instances representing the batched events.
    
    Behavior:
        Adds the event to the queue for the (user_id, channel_id) pair, resets the queue's batch timer,
        and schedules processing after the configured timeout. If the queue reaches MAX_BATCH_SIZE,
        processing is triggered immediately.
    """
    queue_key = _make_queue_key(user_id, channel_id)

    # Create queued message
    queued_msg = QueuedMessage(
        event=event,
        received_at=datetime.now(timezone.utc),
        text=event.get("text", ""),
        slack_ts=event.get("ts", ""),
        thread_ts=event.get("thread_ts")
    )

    # Get or create queue
    if queue_key not in _active_queues or _active_queues[queue_key].status == "processing":
        # Create new queue
        queue = MessageQueue(
            queue_key=queue_key,
            user_id=user_id,
            channel_id=channel_id,
            messages=[queued_msg]
        )
        _active_queues[queue_key] = queue

        logger.info(
            f"Created new queue for {queue_key}, message count: 1"
        )
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
            f"Added to existing queue {queue_key}, "
            f"message count: {len(queue.messages)}"
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

    logger.debug(
        f"Started {BATCH_TIMEOUT_SECONDS}s timer for {queue_key}"
    )


async def _batch_timer(
    queue_key: str,
    processor_callback: callable,
    delay: float
) -> None:
    """
    Waits for the batch delay and then triggers processing of the queue identified by `queue_key`.
    
    Parameters:
        queue_key (str): Composite queue identifier in the form "user_id:channel_id".
        processor_callback (callable): Function to invoke with named arguments `messages`, `user_id`, and `channel_id`.
        delay (float): Number of seconds to wait before triggering processing.
    """
    try:
        await asyncio.sleep(delay)
        logger.info(f"Timer expired for {queue_key}, processing batch")
        await _process_queue(queue_key, processor_callback)
    except asyncio.CancelledError:
        logger.debug(f"Timer cancelled for {queue_key}")
        # This is normal when new messages arrive


async def _process_queue(
    queue_key: str,
    processor_callback: callable
) -> None:
    """
    Process and dispatch all queued messages for the given queue key as a single batch.
    
    Marks the queue as processing, invokes the provided processor_callback with the batched messages as named arguments (messages, user_id, channel_id), logs any processing errors, and removes the queue from in-memory storage when done.
    
    Parameters:
        queue_key (str): Composite key identifying the queue (format "user_id:channel_id").
        processor_callback (callable): Async callable invoked as
            processor_callback(messages=..., user_id=..., channel_id=...).
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

    logger.info(
        f"Processing batch for {queue_key}: "
        f"{len(messages)} message(s)"
    )

    try:
        # Call the processor with batched messages
        await processor_callback(
            messages=messages,
            user_id=user_id,
            channel_id=channel_id
        )

        logger.info(f"Batch processed successfully for {queue_key}")
    except Exception as e:
        logger.error(
            f"Error processing batch for {queue_key}: {e}",
            exc_info=True
        )
    finally:
        # Clean up queue
        if queue_key in _active_queues:
            del _active_queues[queue_key]
            logger.debug(f"Removed queue {queue_key}")


def get_queue(user_id: str, channel_id: str) -> Optional[MessageQueue]:
    """
    Retrieve the active MessageQueue for the specified user and channel.
    
    Returns:
        The MessageQueue for the specified user and channel, or `None` if no active queue exists.
    """
    queue_key = _make_queue_key(user_id, channel_id)
    return _active_queues.get(queue_key)


def get_all_queues() -> Dict[str, MessageQueue]:
    """
    Provide a shallow copy of all active message queues keyed by queue_key.
    
    Returns:
        Dict[str, MessageQueue]: A shallow copy of the mapping from queue_key to its MessageQueue.
    """
    return _active_queues.copy()


def get_queue_stats() -> dict:
    """
    Return aggregate statistics and per-queue summaries for all active message queues.
    
    Returns:
        stats (dict): Summary of current queues containing:
            - total_queues (int): Number of active queues.
            - total_messages (int): Total messages across all queues.
            - accumulating (int): Count of queues with status "accumulating".
            - processing (int): Count of queues with status "processing".
            - queues (list[dict]): Per-queue snapshots where each item contains:
                - key (str): Composite queue key "user_id:channel_id".
                - messages (int): Number of messages in the queue.
                - status (str): Queue status ("accumulating" or "processing").
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
            {
                "key": q.queue_key,
                "messages": len(q.messages),
                "status": q.status
            }
            for q in _active_queues.values()
        ]
    }