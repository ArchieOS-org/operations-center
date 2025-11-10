"""
Slack Events API Webhook Handler (Supabase Integrated)

Receives Slack events, classifies messages using LangChain agent, and stores results in Supabase.
Ported from slack-routes.ts, optimized with LangChain structured output and Supabase storage.

Endpoint: POST /api/slack/events

Features:
- Automatic Pydantic validation (no manual JSON parsing)
- LangChain for provider-agnostic LLM calls
- Supabase for persistent storage
- LangSmith tracing for debugging production issues
"""

from http.server import BaseHTTPRequestHandler
import json
import os
import traceback

# Import from local directory (all files in api/slack/)
try:
    from classifier import classify_message
    from supabase_client import get_supabase
    from slack_verify import verify_slack_signature
    print("✅ All imports successful")
except Exception as e:
    print(f"❌ Import error: {e}")
    print(traceback.format_exc())
    # Define fallback functions so code doesn't crash
    def classify_message(*args, **kwargs):
        raise ImportError("classifier module failed to import")
    def get_supabase(*args, **kwargs):
        raise ImportError("supabase_client module failed to import")
    def verify_slack_signature(*args, **kwargs):
        raise ImportError("slack_verify module failed to import")

# Environment variables
SLACK_SIGNING_SECRET = os.getenv('SLACK_SIGNING_SECRET', '')
SLACK_BYPASS_VERIFY = os.getenv('SLACK_BYPASS_VERIFY', 'false').lower() == 'true'


class handler(BaseHTTPRequestHandler):
    """
    Vercel serverless function handler for Slack Events API

    Handles:
    - URL verification (Slack setup)
    - Message events (classification via LangChain)
    - Signature verification (security)
    - Database persistence (Supabase)

    Endpoint: POST /api/slack/events
    """

    def do_POST(self):
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            raw_body = self.rfile.read(content_length).decode('utf-8')

            # Verify signature (unless bypassed for local development)
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

            # Handle URL verification challenge (Slack setup)
            if body.get('type') == 'url_verification':
                challenge = body.get('challenge', '')
                self.send_text_response(200, challenge)
                return

            # Handle event callback
            if body.get('type') == 'event_callback':
                event = body.get('event', {})
                event_type = event.get('type')

                # Respond immediately to Slack (required < 3 seconds)
                self.send_json_response(200, {'ok': True})

                # Process event asynchronously
                # NOTE: In production, queue this to SQS/Redis/etc. to avoid timeout
                if event_type in ['app_mention', 'message']:
                    self._process_slack_event(event, body.get('event_id'))

                return

            # Unknown event type (acknowledge it anyway)
            self.send_json_response(200, {'ok': True})

        except Exception as e:
            print(f"Error processing Slack webhook: {e}")
            import traceback
            traceback.print_exc()
            self.send_error_response(500, f"Internal server error: {str(e)}")

    def _process_slack_event(self, event: dict, event_id: str):
        """
        Process Slack message event using LangChain classifier and save to Supabase

        Flow:
        1. Extract message data from Slack event
        2. Classify message using LangChain agent
        3. Save classification to Supabase (classifications table)
        4. Log audit entry (audit_log table)

        Args:
            event: Slack event data
            event_id: Unique event ID for deduplication
        """
        message_text = event.get('text', '')
        user_id = event.get('user', '')
        channel_id = event.get('channel', '')
        ts = event.get('ts', '')

        if not message_text:
            return

        try:
            # Classify message using LangChain agent
            # LangChain handles:
            # - Calling the LLM
            # - Parsing JSON response
            # - Validating against Pydantic schema
            # - Retrying on validation errors (if configured)
            # - Tracing with LangSmith (if enabled)
            classification = classify_message(message_text, message_timestamp=ts)

            # Save to Supabase
            supabase = get_supabase()

            # Insert classification record
            result = supabase.table('classifications').insert({
                'event_id': event_id,
                'user_id': user_id,
                'channel_id': channel_id,
                'message_ts': ts,
                'message': message_text,
                'classification': classification.model_dump(),
                'message_type': classification.message_type.value,
                'task_key': classification.task_key.value if classification.task_key else None,
                'group_key': classification.group_key.value if classification.group_key else None,
                'assignee_hint': classification.assignee_hint,
                'due_date': classification.due_date,
                'confidence': classification.confidence
            }).execute()

            classification_id = result.data[0]['id']
            print(f"✅ Saved classification: {classification_id}")
            print(f"   Message type: {classification.message_type.value}")
            print(f"   Confidence: {classification.confidence}")

            # Log to audit_log (optional but recommended)
            try:
                supabase.table('audit_log').insert({
                    'action': 'classification_created',
                    'actor_id': user_id,
                    'resource_type': 'classification',
                    'resource_id': classification_id,
                    'metadata': {
                        'message_type': classification.message_type.value,
                        'confidence': classification.confidence,
                        'channel_id': channel_id
                    }
                }).execute()
            except Exception as audit_error:
                # Don't fail the main operation if audit logging fails
                print(f"⚠️  Audit log failed (non-critical): {audit_error}")

            # TODO: Optionally post result back to Slack thread
            # self._post_classification_to_slack(channel_id, ts, classification)

        except Exception as e:
            print(f"❌ Error classifying message '{message_text[:50]}...': {e}")
            import traceback
            traceback.print_exc()

            # TODO: Log to error tracking service (Sentry, DataDog, etc.)
            # sentry_sdk.capture_exception(e)

    def _post_classification_to_slack(self, channel: str, thread_ts: str, classification):
        """
        Post classification result back to Slack thread

        Requires:
        - SLACK_BOT_TOKEN environment variable
        - Slack SDK: pip install slack-sdk

        Example:
            from slack_sdk import WebClient
            client = WebClient(token=os.getenv('SLACK_BOT_TOKEN'))
            client.chat_postMessage(
                channel=channel,
                thread_ts=thread_ts,
                text=f"Classified as: {classification.message_type.value}"
            )
        """
        pass

    def send_json_response(self, status_code: int, data: dict):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def send_text_response(self, status_code: int, text: str):
        """Send plain text response (for URL verification challenge)"""
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
    print("=" * 80)
    print("Slack Events API (Supabase Integrated) running on http://localhost:8000")
    print("=" * 80)
    print("\nTest URL verification:")
    print('curl -X POST http://localhost:8000 \\')
    print('  -H "Content-Type: application/json" \\')
    print('  -d \'{"type":"url_verification","challenge":"test123"}\'')
    print("\nTest message classification:")
    print('curl -X POST http://localhost:8000 \\')
    print('  -H "Content-Type: application/json" \\')
    print('  -d \'{"type":"event_callback","event":{"type":"message","text":"We got an offer on 123 Main St by Friday","user":"U123","channel":"C456","ts":"1234567890.123456"},"event_id":"Ev123"}\'')
    print("\n" + "=" * 80)
    server.serve_forever()
