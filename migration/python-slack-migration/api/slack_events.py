"""
Slack Events API Webhook Handler (Vercel Serverless Function)

Receives Slack events, classifies messages, and stores results.
Ported from slack-routes.ts

Endpoint: POST /api/slack/events
"""

from http.server import BaseHTTPRequestHandler
import json
import os
import hmac
import hashlib
import time

# Import from parent directory
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from classifier import classify_message

# Environment variables
SLACK_SIGNING_SECRET = os.getenv('SLACK_SIGNING_SECRET', '')
SLACK_BYPASS_VERIFY = os.getenv('SLACK_BYPASS_VERIFY', 'false').lower() == 'true'


def verify_slack_signature(signing_secret: str, timestamp: str, body: str, signature: str) -> bool:
    """
    Verify Slack request signature
    Ported from slackVerify.ts
    """
    if not signing_secret or not signature or not timestamp:
        return False

    # Check timestamp (reject if > 5 minutes old)
    current_time = int(time.time())
    request_time = int(timestamp)
    if abs(current_time - request_time) > 300:
        return False

    # Calculate expected signature
    sig_basestring = f'v0:{timestamp}:{body}'
    expected_signature = 'v0=' + hmac.new(
        signing_secret.encode(),
        sig_basestring.encode(),
        hashlib.sha256
    ).hexdigest()

    # Constant-time comparison
    return hmac.compare_digest(expected_signature, signature)


class handler(BaseHTTPRequestHandler):
    """
    Vercel serverless function handler

    Endpoint: POST /api/slack/events
    """

    def do_POST(self):
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            raw_body = self.rfile.read(content_length).decode('utf-8')

            # Verify signature (unless bypassed for dev)
            if not SLACK_BYPASS_VERIFY:
                signature = self.headers.get('X-Slack-Signature', '')
                timestamp = self.headers.get('X-Slack-Request-Timestamp', '')

                if not verify_slack_signature(SLACK_SIGNING_SECRET, timestamp, raw_body, signature):
                    self.send_error_response(401, "Invalid signature")
                    return

            # Parse JSON body
            try:
                body = json.loads(raw_body)
            except json.JSONDecodeError:
                self.send_error_response(400, "Invalid JSON")
                return

            # Handle URL verification challenge
            if body.get('type') == 'url_verification':
                challenge = body.get('challenge', '')
                self.send_text_response(200, challenge)
                return

            # Handle event callback
            if body.get('type') == 'event_callback':
                event = body.get('event', {})
                event_type = event.get('type')

                # Respond immediately to Slack (required < 3s)
                self.send_json_response(200, {'ok': True})

                # Process event asynchronously (in production, queue this)
                if event_type in ['app_mention', 'message']:
                    self._process_slack_event(event, body.get('event_id'))

                return

            # Unknown event type
            self.send_json_response(200, {'ok': True})

        except Exception as e:
            print(f"Error processing Slack webhook: {e}")
            import traceback
            traceback.print_exc()
            self.send_error_response(500, f"Internal server error: {str(e)}")

    def _process_slack_event(self, event: dict, event_id: str):
        """
        Process Slack message event

        In production, this should be queued (SQS, etc.) to avoid timeout.
        For now, we process inline with classification.
        """
        message_text = event.get('text', '')
        user_id = event.get('user', '')
        channel_id = event.get('channel', '')
        ts = event.get('ts', '')

        if not message_text:
            return

        # Classify message
        try:
            classification = classify_message(message_text)

            # Store classification result (in production, save to database)
            result = {
                'event_id': event_id,
                'user_id': user_id,
                'channel_id': channel_id,
                'ts': ts,
                'message': message_text,
                'classification': classification.model_dump()
            }

            # TODO: Save to database (DynamoDB, PostgreSQL, etc.)
            print(f"Classification result: {json.dumps(result, indent=2)}")

            # TODO: Optionally post result back to Slack thread
            # self._post_to_slack(channel_id, ts, classification)

        except Exception as e:
            print(f"Error classifying message: {e}")
            import traceback
            traceback.print_exc()

    def send_json_response(self, status_code: int, data: dict):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def send_text_response(self, status_code: int, text: str):
        """Send plain text response (for challenge)"""
        self.send_response(status_code)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(text.encode())

    def send_error_response(self, status_code: int, message: str):
        """Send error response"""
        self.send_json_response(status_code, {
            'ok': False,
            'error': message
        })


# For local testing
if __name__ == "__main__":
    from http.server import HTTPServer

    # Set test environment
    os.environ['SLACK_BYPASS_VERIFY'] = 'true'

    server = HTTPServer(('localhost', 8000), handler)
    print("Slack Events API running on http://localhost:8000")
    print("\nTest with URL verification:")
    print('curl -X POST http://localhost:8000 -H "Content-Type: application/json" -d \'{"type":"url_verification","challenge":"test123"}\'')
    print("\nTest with message event:")
    print('curl -X POST http://localhost:8000 -H "Content-Type: application/json" -d \'{"type":"event_callback","event":{"type":"message","text":"We got an offer on 123 Main St","user":"U123","channel":"C456","ts":"1234567890.123456"},"event_id":"Ev123"}\'')
    server.serve_forever()
