"""Message queue for batching rapid consecutive Slack messages."""

from .message_queue import MessageQueue, enqueue_message, get_queue

__all__ = ["MessageQueue", "enqueue_message", "get_queue"]
