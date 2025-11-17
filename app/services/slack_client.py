"""Slack client for posting acknowledgment messages.

Sends acknowledgments back to Slack channels when tasks or listings
are detected and created in the database.
"""

import logging
from typing import Optional
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

from app.config.settings import get_settings
from app.schemas.classification import ClassificationV1, MessageType

logger = logging.getLogger(__name__)

# Initialize Slack client (singleton)
settings = get_settings()
slack_client = WebClient(token=settings.SLACK_BOT_TOKEN)


async def send_task_acknowledgment(
    channel: str,
    thread_ts: Optional[str] = None
) -> bool:
    """Send task detection acknowledgment to Slack.

    Args:
        channel: Slack channel ID (e.g., "C0XXXXXX")
        thread_ts: Optional thread timestamp for threaded reply

    Returns:
        True if successful, False otherwise
    """
    try:
        response = slack_client.chat_postMessage(
            channel=channel,
            text="✅ Task detected and added to your queue!",
            thread_ts=thread_ts
        )

        logger.info(
            f"Posted task acknowledgment to {channel}, ts={response['ts']}"
        )
        return True

    except SlackApiError as e:
        logger.error(
            f"Failed to post task acknowledgment to {channel}: {e.response['error']}",
            exc_info=True
        )
        return False
    except Exception as e:
        logger.error(
            f"Unexpected error posting task acknowledgment: {e}",
            exc_info=True
        )
        return False


async def send_listing_acknowledgment(
    channel: str,
    listing_type: str,
    address: str,
    thread_ts: Optional[str] = None
) -> bool:
    """Send listing detection acknowledgment to Slack.

    Args:
        channel: Slack channel ID
        listing_type: Type of listing (e.g., "SALE_LISTING")
        address: Property address
        thread_ts: Optional thread timestamp for threaded reply

    Returns:
        True if successful, False otherwise
    """
    # Format listing type for display (remove underscores, title case)
    formatted_type = listing_type.replace("_", " ").title()

    try:
        response = slack_client.chat_postMessage(
            channel=channel,
            text=f"🏠 Listing detected: {formatted_type} - {address}",
            thread_ts=thread_ts
        )

        logger.info(
            f"Posted listing acknowledgment to {channel}, ts={response['ts']}"
        )
        return True

    except SlackApiError as e:
        logger.error(
            f"Failed to post listing acknowledgment to {channel}: {e.response['error']}",
            exc_info=True
        )
        return False
    except Exception as e:
        logger.error(
            f"Unexpected error posting listing acknowledgment: {e}",
            exc_info=True
        )
        return False


async def send_acknowledgment(
    classification: ClassificationV1,
    channel: str,
    thread_ts: Optional[str] = None
) -> bool:
    """Route to appropriate acknowledgment based on classification.

    Args:
        classification: Classification result
        channel: Slack channel ID
        thread_ts: Optional thread timestamp

    Returns:
        True if acknowledgment sent, False otherwise (including IGNORE/INFO_REQUEST)
    """
    message_type = classification.message_type

    if message_type == MessageType.GROUP:
        # Listing detected
        listing_type = classification.group_key.value if classification.group_key else "UNKNOWN"
        address = classification.listing.address if classification.listing else "Unknown Address"

        return await send_listing_acknowledgment(
            channel=channel,
            listing_type=listing_type,
            address=address,
            thread_ts=thread_ts
        )

    elif message_type == MessageType.STRAY:
        # Task detected
        return await send_task_acknowledgment(
            channel=channel,
            thread_ts=thread_ts
        )

    elif message_type in [MessageType.INFO_REQUEST, MessageType.IGNORE]:
        # No acknowledgment needed
        logger.debug(
            f"Skipping acknowledgment for message_type={message_type.value}"
        )
        return False

    else:
        logger.warning(
            f"Unknown message_type={message_type}, skipping acknowledgment"
        )
        return False
