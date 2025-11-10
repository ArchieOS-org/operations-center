"""
Messages API Endpoint (Vercel Serverless Function)

Returns messages for a specific conversation.
Endpoint: GET /api/messages?phone_number=+14155551234
"""

from http.server import BaseHTTPRequestHandler
import json
import os
from urllib.parse import urlparse, parse_qs

# Import from parent directory
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from supabase import create_client, Client

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_KEY')
)


class handler(BaseHTTPRequestHandler):
    """
    Vercel serverless function handler

    Endpoint: GET /api/messages?phone_number=+14155551234&limit=100
    """

    def do_GET(self):
        try:
            # Parse query parameters
            parsed_url = urlparse(self.path)
            query_params = parse_qs(parsed_url.query)

            phone_number = query_params.get('phone_number', [''])[0]
            limit = int(query_params.get('limit', ['100'])[0])

            if not phone_number:
                self.send_error_response(400, "Missing phone_number parameter")
                return

            # Validate limit
            if limit < 1 or limit > 200:
                self.send_error_response(400, "Limit must be between 1 and 200")
                return

            # Get conversation ID for this phone number
            conversation = supabase.table('conversations').select('id').eq(
                'phone_number', phone_number
            ).eq('agent_type', 'classifier').execute()

            if not conversation.data:
                self.send_error_response(404, f"No conversation found for {phone_number}")
                return

            conversation_id = conversation.data[0]['id']

            # Get messages
            messages = supabase.table('messages').select(
                'id, conversation_id, role, content, twilio_sid, classification, created_at'
            ).eq('conversation_id', conversation_id).order(
                'created_at', desc=False
            ).limit(limit).execute()

            # Get total count
            count_response = supabase.table('messages').select(
                'id', count='exact'
            ).eq('conversation_id', conversation_id).execute()

            total = count_response.count if hasattr(count_response, 'count') else 0

            # Return response
            self.send_json_response(200, {
                'messages': messages.data,
                'total': total,
                'phone_number': phone_number,
                'conversation_id': conversation_id
            })

        except Exception as e:
            print(f"Error fetching messages: {e}")
            import traceback
            traceback.print_exc()
            self.send_error_response(500, f"Internal server error: {str(e)}")

    def send_json_response(self, status_code: int, data: dict):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')  # Allow Swift app to access
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

    server = HTTPServer(('localhost', 8002), handler)
    print("Messages API running on http://localhost:8002")
    print("Test with: curl 'http://localhost:8002?phone_number=%2B14155551234'")
    server.serve_forever()
