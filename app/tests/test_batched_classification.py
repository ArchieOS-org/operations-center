"""Tests for batched message classification utilities."""

from datetime import datetime, timezone
from app.queue.message_queue import QueuedMessage
from app.workflows.batched_classification import (
    batch_messages_for_classification,
    extract_all_message_timestamps,
    get_primary_thread_ts,
)


def test_batch_single_message():
    """Test batching a single message returns text as-is."""
    messages = [
        QueuedMessage(
            event={"text": "New sale listing at 123 Main St", "ts": "1234567890.123456"},
            received_at=datetime.now(timezone.utc),
            text="New sale listing at 123 Main St",
            slack_ts="1234567890.123456",
            thread_ts=None
        )
    ]

    result = batch_messages_for_classification(messages)
    assert result == "New sale listing at 123 Main St"


def test_batch_multiple_messages():
    """Test batching multiple messages combines them with context."""
    messages = [
        QueuedMessage(
            event={"text": "New listing", "ts": "1234567890.123456"},
            received_at=datetime.now(timezone.utc),
            text="New listing",
            slack_ts="1234567890.123456",
            thread_ts=None
        ),
        QueuedMessage(
            event={"text": "at 123 Main St", "ts": "1234567891.123456"},
            received_at=datetime.now(timezone.utc),
            text="at 123 Main St",
            slack_ts="1234567891.123456",
            thread_ts=None
        ),
        QueuedMessage(
            event={"text": "$500k asking price", "ts": "1234567892.123456"},
            received_at=datetime.now(timezone.utc),
            text="$500k asking price",
            slack_ts="1234567892.123456",
            thread_ts=None
        ),
    ]

    result = batch_messages_for_classification(messages)

    assert "User sent the following messages in quick succession" in result
    assert "Classify these as a single unit" in result
    assert "Message 1" in result
    assert "Message 2" in result
    assert "Message 3" in result
    assert "New listing" in result
    assert "at 123 Main St" in result
    assert "$500k asking price" in result


def test_extract_all_message_timestamps():
    """Test extracting timestamps from batched messages."""
    messages = [
        QueuedMessage(event={"text": "msg1", "ts": "1234567890.123456"}, received_at=datetime.now(timezone.utc), text="msg1", slack_ts="1234567890.123456", thread_ts=None),
        QueuedMessage(event={"text": "msg2", "ts": "1234567891.123456"}, received_at=datetime.now(timezone.utc), text="msg2", slack_ts="1234567891.123456", thread_ts=None),
        QueuedMessage(event={"text": "msg3", "ts": "1234567892.123456"}, received_at=datetime.now(timezone.utc), text="msg3", slack_ts="1234567892.123456", thread_ts=None),
    ]

    timestamps = extract_all_message_timestamps(messages)

    assert len(timestamps) == 3
    assert timestamps[0] == "1234567890.123456"
    assert timestamps[1] == "1234567891.123456"
    assert timestamps[2] == "1234567892.123456"


def test_get_primary_thread_ts_no_thread():
    """Test getting thread timestamp when no messages are in a thread."""
    messages = [
        QueuedMessage(event={"text": "msg1", "ts": "1234567890.123456"}, received_at=datetime.now(timezone.utc), text="msg1", slack_ts="1234567890.123456", thread_ts=None),
        QueuedMessage(event={"text": "msg2", "ts": "1234567891.123456"}, received_at=datetime.now(timezone.utc), text="msg2", slack_ts="1234567891.123456", thread_ts=None),
    ]

    thread_ts = get_primary_thread_ts(messages)
    assert thread_ts is None


def test_get_primary_thread_ts_with_thread():
    """Test getting thread timestamp when messages are in a thread."""
    messages = [
        QueuedMessage(event={"text": "msg1", "ts": "1234567890.123456"}, received_at=datetime.now(timezone.utc), text="msg1", slack_ts="1234567890.123456", thread_ts=None),
        QueuedMessage(event={"text": "msg2", "ts": "1234567891.123456", "thread_ts": "1234567890.000000"}, received_at=datetime.now(timezone.utc), text="msg2", slack_ts="1234567891.123456", thread_ts="1234567890.000000"),
        QueuedMessage(event={"text": "msg3", "ts": "1234567892.123456", "thread_ts": "1234567890.000000"}, received_at=datetime.now(timezone.utc), text="msg3", slack_ts="1234567892.123456", thread_ts="1234567890.000000"),
    ]

    thread_ts = get_primary_thread_ts(messages)
    assert thread_ts == "1234567890.000000"


def test_batch_empty_messages():
    """Test batching empty message list."""
    messages: list = []
    result = batch_messages_for_classification(messages)
    assert result == ""
