"""Tests for Slack intake workflow validation."""

import pytest
from app.queue.message_queue import QueuedMessage
from app.workflows.slack_intake import validate_messages


@pytest.mark.asyncio
async def test_validate_messages_empty():
    """Test validation fails for empty message list."""
    result = await validate_messages([], "U123456")
    assert result is False


@pytest.mark.asyncio
async def test_validate_messages_bot():
    """Test validation fails for bot users."""
    messages = [
        QueuedMessage(text="Bot message", slack_ts="1234567890.123456", thread_ts=None)
    ]
    result = await validate_messages(messages, "B123456")  # Bot IDs start with 'B'
    assert result is False


@pytest.mark.asyncio
async def test_validate_messages_missing_user_id():
    """Test validation fails for missing user_id."""
    messages = [
        QueuedMessage(text="Test message", slack_ts="1234567890.123456", thread_ts=None)
    ]
    result = await validate_messages(messages, "")
    assert result is False


@pytest.mark.asyncio
async def test_validate_messages_none_user_id():
    """Test validation fails for None user_id."""
    messages = [
        QueuedMessage(text="Test message", slack_ts="1234567890.123456", thread_ts=None)
    ]
    result = await validate_messages(messages, None)
    assert result is False


@pytest.mark.asyncio
async def test_validate_messages_valid_user():
    """Test validation succeeds for valid user messages."""
    messages = [
        QueuedMessage(text="Test message", slack_ts="1234567890.123456", thread_ts=None)
    ]
    result = await validate_messages(messages, "U123456")  # User IDs start with 'U'
    assert result is True
