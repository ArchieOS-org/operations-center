"""
Conversations API Endpoint (Vercel Serverless Function)

Returns list of all SMS conversations for the Swift supervisor dashboard.
Endpoint: GET /api/conversations
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

    Endpoint: GET /api/conversations?limit=50&offset=0
    """

    def do_GET(self):
        try:
            # Parse query parameters
            parsed_url = urlparse(self.path)
            query_params = parse_qs(parsed_url.query)

            limit = int(query_params.get('limit', ['50'])[0])
            offset = int(query_params.get('offset', ['0'])[0])

            # Validate limits
            if limit < 1 or limit > 100:
                self.send_error_response(400, "Limit must be between 1 and 100")
                return

            if offset < 0:
                self.send_error_response(400, "Offset must be >= 0")
                return

            # Query Supabase using the recent_conversations view
            response = supabase.from_('recent_conversations').select(
                'conversation_id, phone_number, agent_type, last_message_at, '
                'user_name, last_message, message_count'
            ).order('last_message_at', desc=True).range(
                offset, offset + limit - 1
            ).execute()

            # Get total count
            count_response = supabase.from_('conversations').select(
                'id', count='exact'
            ).execute()

            total = count_response.count if hasattr(count_response, 'count') else 0

            # Return response
            self.send_json_response(200, {
                'conversations': response.data,
                'total': total,
                'limit': limit,
                'offset': offset
            })

        except Exception as e:
            print(f"Error fetching conversations: {e}")
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

    server = HTTPServer(('localhost', 8001), handler)
    print("Conversations API running on http://localhost:8001")
    print("Test with: curl http://localhost:8001?limit=10")
    server.serve_forever()
