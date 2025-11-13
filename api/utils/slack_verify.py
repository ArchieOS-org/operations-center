"""
Slack Signature Verification Utility

Verifies Slack webhook requests using HMAC-SHA256 signature verification.
Ported from slackVerify.ts
"""

import hmac
import hashlib
import time


def verify_slack_signature(
    signing_secret: str,
    timestamp: str,
    body: str,
    signature: str
) -> bool:
    """
    Verify Slack request signature using HMAC-SHA256

    Implements Slack's signature verification to ensure requests are authentic.
    Protects against replay attacks by checking timestamp.

    Args:
        signing_secret: Slack app signing secret
        timestamp: X-Slack-Request-Timestamp header
        body: Raw request body string
        signature: X-Slack-Signature header (starts with 'v0=')

    Returns:
        bool: True if signature is valid, False otherwise

    Security Notes:
        - Rejects requests older than 5 minutes to prevent replay attacks
        - Uses constant-time comparison to prevent timing attacks
    """
    if not signing_secret or not signature or not timestamp:
        return False

    # Check timestamp (reject if > 5 minutes old to prevent replay attacks)
    try:
        current_time = int(time.time())
        request_time = int(timestamp)
        if abs(current_time - request_time) > 300:
            return False
    except (ValueError, TypeError):
        return False

    # Calculate expected signature
    sig_basestring = f'v0:{timestamp}:{body}'
    expected_signature = 'v0=' + hmac.new(
        signing_secret.encode(),
        sig_basestring.encode(),
        hashlib.sha256
    ).hexdigest()

    # Constant-time comparison to prevent timing attacks
    return hmac.compare_digest(expected_signature, signature)
