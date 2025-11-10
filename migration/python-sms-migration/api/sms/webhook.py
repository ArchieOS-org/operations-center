"""
Twilio SMS Webhook Handler (Vercel Serverless Function)

Receives SMS messages from Twilio, classifies them, and stores in Supabase.
Ported from slack-routes.ts
"""

from http.server import BaseHTTPRequestHandler
import json
import os
from urllib.parse import parse_qs
from datetime import datetime

# Import from parent directory
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from classifier import classify_message
from supabase import create_client, Client

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_KEY')
)


class handler(BaseHTTPRequestHandler):
    """
    Vercel serverless function handler

    Endpoint: POST /api/sms/webhook
    """

    def do_POST(self):
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')

            # Parse Twilio webhook parameters
            params = parse_qs(body)

            phone_number = params.get('From', [''])[0]
            message_text = params.get('Body', [''])[0]
            twilio_sid = params.get('MessageSid', [''])[0]

            if not phone_number or not message_text:
                self.send_error_response(400, "Missing From or Body parameter")
                return

            # Verify Twilio signature (optional but recommended)
            # TODO: Implement Twilio signature verification
            # from twilio.request_validator import RequestValidator
            # validator = RequestValidator(os.getenv('TWILIO_AUTH_TOKEN'))
            # if not validator.validate(url, params, signature):
            #     self.send_error_response(401, "Invalid signature")
            #     return

            # Classify message using OpenAI
            timestamp = datetime.utcnow().isoformat()
            classification = classify_message(message_text, timestamp)

            # Get or create user
            user = supabase.table('users').select('*').eq(
                'phone_number', phone_number
            ).execute()

            if not user.data:
                # Create new user
                supabase.table('users').insert({
                    'phone_number': phone_number,
                    'created_at': timestamp
                }).execute()

            # Get or create conversation
            conversation = supabase.table('conversations').select('id').eq(
                'phone_number', phone_number
            ).eq('agent_type', 'classifier').execute()

            if not conversation.data:
                # Create new conversation
                conv_result = supabase.table('conversations').insert({
                    'phone_number': phone_number,
                    'agent_type': 'classifier',
                    'created_at': timestamp,
                    'last_message_at': timestamp
                }).execute()
                conversation_id = conv_result.data[0]['id']
            else:
                conversation_id = conversation.data[0]['id']
                # Update last_message_at
                supabase.table('conversations').update({
                    'last_message_at': timestamp
                }).eq('id', conversation_id).execute()

            # Save message with classification
            supabase.table('messages').insert({
                'conversation_id': conversation_id,
                'role': 'user',
                'content': message_text,
                'twilio_sid': twilio_sid,
                'classification': classification.model_dump(),
                'created_at': timestamp
            }).execute()

            # Return success response
            self.send_json_response(200, {
                'success': True,
                'message': 'Message classified and saved',
                'classification': {
                    'message_type': classification.message_type.value,
                    'confidence': classification.confidence
                }
            })

        except Exception as e:
            # Log error and return 500
            print(f"Error processing webhook: {e}")
            import traceback
            traceback.print_exc()
            self.send_error_response(500, f"Internal server error: {str(e)}")

    def send_json_response(self, status_code: int, data: dict):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def send_error_response(self, status_code: int, message: str):
        """Send error response"""
        self.send_json_response(status_code, {
            'success': False,
            'error': message
        })


# For local testing
if __name__ == "__main__":
    from http.server import HTTPServer

    server = HTTPServer(('localhost', 8000), handler)
    print("Server running on http://localhost:8000")
    print("Test with: curl -X POST http://localhost:8000 -d 'From=+14155551234&Body=Test message&MessageSid=SM123'")
    server.serve_forever()
