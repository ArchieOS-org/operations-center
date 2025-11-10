"""
Slack Events API Webhook Handler (Complete Integration)
Self-contained serverless function for Vercel with LangChain + Supabase
"""

from http.server import BaseHTTPRequestHandler
import json
import os
import hmac
import hashlib
import time
from typing import Optional, Literal
from enum import Enum

# Pydantic imports (for schema validation)
try:
    from pydantic import BaseModel, Field
    PYDANTIC_AVAILABLE = True
except ImportError:
    PYDANTIC_AVAILABLE = False
    print("⚠️  Pydantic not available")

# LangChain imports (for LLM integration)
try:
    from langchain_openai import ChatOpenAI
    LANGCHAIN_AVAILABLE = True
except ImportError:
    LANGCHAIN_AVAILABLE = False
    print("⚠️  LangChain not available")

# Supabase imports (for database)
try:
    from supabase import create_client
    SUPABASE_AVAILABLE = True
except ImportError:
    SUPABASE_AVAILABLE = False
    print("⚠️  Supabase not available")

# Environment variables
SLACK_SIGNING_SECRET = os.getenv('SLACK_SIGNING_SECRET', '')
SLACK_BYPASS_VERIFY_RAW = os.getenv('SLACK_BYPASS_VERIFY', 'false')
SLACK_BYPASS_VERIFY = SLACK_BYPASS_VERIFY_RAW.lower() == 'true'
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
OPENAI_MODEL = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')
SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_KEY = os.getenv('SUPABASE_KEY', '')

# Debug logging for environment variables
print("🔧 Environment Variable Debug:")
print(f"   SLACK_BYPASS_VERIFY_RAW: '{SLACK_BYPASS_VERIFY_RAW}'")
print(f"   SLACK_BYPASS_VERIFY (parsed): {SLACK_BYPASS_VERIFY}")
print(f"   SLACK_SIGNING_SECRET: {'SET' if SLACK_SIGNING_SECRET else 'NOT SET'}")
print(f"   OPENAI_API_KEY: {'SET' if OPENAI_API_KEY else 'NOT SET'}")
print(f"   OPENAI_MODEL: {OPENAI_MODEL}")
print(f"   SUPABASE_URL: {SUPABASE_URL}")
print(f"   SUPABASE_KEY: {'SET' if SUPABASE_KEY else 'NOT SET'}")
if SUPABASE_KEY:
    print(f"   SUPABASE_KEY length: {len(SUPABASE_KEY)}")
    print(f"   SUPABASE_KEY preview: {SUPABASE_KEY[:20]}...{SUPABASE_KEY[-20:]}")
    print(f"   SUPABASE_KEY repr: {repr(SUPABASE_KEY[:30])}")
print(f"   PYDANTIC_AVAILABLE: {PYDANTIC_AVAILABLE}")
print(f"   LANGCHAIN_AVAILABLE: {LANGCHAIN_AVAILABLE}")
print(f"   SUPABASE_AVAILABLE: {SUPABASE_AVAILABLE}")


# ============================================================================
# SLACK SIGNATURE VERIFICATION
# ============================================================================

def verify_slack_signature(signing_secret: str, timestamp: str, body: str, signature: str) -> bool:
    """Verify Slack request signature using HMAC-SHA256"""
    if not signing_secret or not signature or not timestamp:
        return False

    try:
        current_time = int(time.time())
        request_time = int(timestamp)
        if abs(current_time - request_time) > 300:
            return False
    except (ValueError, TypeError):
        return False

    sig_basestring = f'v0:{timestamp}:{body}'
    expected_signature = 'v0=' + hmac.new(
        signing_secret.encode(),
        sig_basestring.encode(),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(expected_signature, signature)


# ============================================================================
# PYDANTIC SCHEMA (Classification V1)
# ============================================================================

if PYDANTIC_AVAILABLE:
    class MessageType(str, Enum):
        """Message classification types"""
        GROUP = "GROUP"
        STRAY = "STRAY"
        INFO_REQUEST = "INFO_REQUEST"
        IGNORE = "IGNORE"

    class ListingType(str, Enum):
        """Listing types (SALE or LEASE)"""
        SALE = "SALE"
        LEASE = "LEASE"

    class GroupKey(str, Enum):
        """Valid group_key values for GROUP message types"""
        SALE_LISTING = "SALE_LISTING"
        LEASE_LISTING = "LEASE_LISTING"
        SALE_LEASE_LISTING = "SALE_LEASE_LISTING"
        SOLD_SALE_LEASE_LISTING = "SOLD_SALE_LEASE_LISTING"
        RELIST_LISTING = "RELIST_LISTING"
        RELIST_LISTING_DEAL_SALE_OR_LEASE = "RELIST_LISTING_DEAL_SALE_OR_LEASE"
        BUY_OR_LEASED = "BUY_OR_LEASED"
        MARKETING_AGENDA_TEMPLATE = "MARKETING_AGENDA_TEMPLATE"

    class TaskKey(str, Enum):
        """Valid task_key values for STRAY message types"""
        SALE_ACTIVE_TASKS = "SALE_ACTIVE_TASKS"
        SALE_SOLD_TASKS = "SALE_SOLD_TASKS"
        SALE_CLOSING_TASKS = "SALE_CLOSING_TASKS"
        LEASE_ACTIVE_TASKS = "LEASE_ACTIVE_TASKS"
        LEASE_LEASED_TASKS = "LEASE_LEASED_TASKS"
        LEASE_CLOSING_TASKS = "LEASE_CLOSING_TASKS"
        LEASE_ACTIVE_TASKS_ARLYN = "LEASE_ACTIVE_TASKS_ARLYN"
        RELIST_LISTING_DEAL_SALE = "RELIST_LISTING_DEAL_SALE"
        RELIST_LISTING_DEAL_LEASE = "RELIST_LISTING_DEAL_LEASE"
        BUYER_DEAL = "BUYER_DEAL"
        BUYER_DEAL_CLOSING_TASKS = "BUYER_DEAL_CLOSING_TASKS"
        LEASE_TENANT_DEAL = "LEASE_TENANT_DEAL"
        LEASE_TENANT_DEAL_CLOSING_TASKS = "LEASE_TENANT_DEAL_CLOSING_TASKS"
        PRECON_DEAL = "PRECON_DEAL"
        MUTUAL_RELEASE_STEPS = "MUTUAL_RELEASE_STEPS"
        OPS_MISC_TASK = "OPS_MISC_TASK"

    class Listing(BaseModel):
        """Listing information"""
        type: Optional[ListingType] = None
        address: Optional[str] = None

    class ClassificationV1(BaseModel):
        """Message classification result"""
        schema_version: Literal[1] = 1
        message_type: MessageType
        task_key: Optional[TaskKey] = None
        group_key: Optional[GroupKey] = None
        listing: Listing
        assignee_hint: Optional[str] = None
        due_date: Optional[str] = None
        task_title: Optional[str] = Field(None, max_length=80)
        confidence: float = Field(ge=0, le=1)
        explanations: Optional[list[str]] = None


# ============================================================================
# LANGCHAIN CLASSIFIER
# ============================================================================

CLASSIFICATION_INSTRUCTIONS = """
System (ultra-brief, non-negotiable)
You transform real-estate operations Slack messages into JSON only that conforms to the developer instructions and schema.
Never fabricate fields. If irrelevant to ops, return IGNORE. If operational but incomplete, return INFO_REQUEST with brief explanations.
Do not output prose or code fences—JSON only.

Developer (full behavior spec)
Objective
Classify a Slack message and extract fields into a strict JSON object that matches the schema. Return only valid JSON.

Message types
• GROUP — The message declares or updates a listing container (i.e., "this is a listing entity").
Allowed group_key values:
• SALE_LISTING
• LEASE_LISTING
• SALE_LEASE_LISTING
• SOLD_SALE_LEASE_LISTING
• RELIST_LISTING
• RELIST_LISTING_DEAL_SALE_OR_LEASE
• BUY_OR_LEASED
• MARKETING_AGENDA_TEMPLATE
• STRAY - A single actionable task that does not declare/update a listing group. Pick exactly one task_key: prefer the catalog below; otherwise use OPS_MISC_TASK for any clear request.
• INFO_REQUEST - Operational/real-estate content but missing specifics to proceed. Explain what is missing in explanations.
• IGNORE - Chit-chat, reactions, or content unrelated to operations.

Decision rules & tie-breaks
• Choose exactly one message_type.
• Prefer GROUP if a message both declares/updates a listing and requests tasks.
• GROUP ⇒ set group_key (one of the allowed values) and task_key:null.
• STRAY ⇒ set exactly one task_key (from taxonomy) and group_key:null.
• If multiple task candidates appear, choose the most specific (e.g., *_CLOSING_* over *_ACTIVE_*). If ambiguity remains, use INFO_REQUEST and explain briefly.

Listing types (for listing.type)
• Only set "SALE" or "LEASE" if explicit OR unambiguously implied by the hints below. Otherwise null.
  Hints for SALE (non-exhaustive): sold, conditional, firm, purchase agreement/APS, buyer deal, closing date (sale), MLS #, open house, staging, deposit (sale), conditions removal.
  Hints for LEASE (non-exhaustive): lease/leased, tenant/landlord, showings schedule, OTL/offer to lease, LOI, rent/TMI/NNN, possession date (lease), renewal, term/rate per month.

Assignees & addresses
• assignee_hint → Person explicitly named or @-mentioned. If only pronouns ("he/she/they") or only a team ("Marketing"), set null.
• listing.address → Extract only if explicitly present in text OR clearly present within provided links/attachment titles.

Dates & timezone policy
• Timezone: America/Toronto. Use the provided message timestamp (ISO) as the reference for resolving relative dates.
• due_date → Use ISO formats: Date: YYYY-MM-DD; DateTime: YYYY-MM-DDThh:mm (24h).
• Relative phrases:
  - "by Friday"/"this Friday": choose the next occurrence of that weekday on/after the message timestamp; if no time provided, default to 17:00 local.
  - Day-only like "Oct 3": use the next such date on/after the message timestamp; if year omitted, use the message year; default time 17:00 if time missing.
  - If still ambiguous or contradictory, set null and add a brief explanation.

Best-effort vs nulls
• Prefer best-effort fills with a short explanation when reasonable (e.g., listing.type from strong hints, relative dates).
• Never fabricate addresses or names.

Task taxonomy (valid task_key values for STRAY)
Sale Listings
• SALE_ACTIVE_TASKS, SALE_SOLD_TASKS, SALE_CLOSING_TASKS

Lease Listings
• LEASE_ACTIVE_TASKS, LEASE_LEASED_TASKS, LEASE_CLOSING_TASKS, LEASE_ACTIVE_TASKS_ARLYN (special case)

Re-List Listings
• RELIST_LISTING_DEAL_SALE, RELIST_LISTING_DEAL_LEASE

Buyer Deals
• BUYER_DEAL, BUYER_DEAL_CLOSING_TASKS

Lease Tenant Deals
• LEASE_TENANT_DEAL, LEASE_TENANT_DEAL_CLOSING_TASKS

Pre-Con Deals
• PRECON_DEAL

Mutual Release
• MUTUAL_RELEASE_STEPS

General Ops
• OPS_MISC_TASK (any actionable request without a specific template)

Extraction rules
• listing.address → Street/building/unit only if explicit in text or provided links; otherwise null.
• assignee_hint → name/@mention only; pronouns/teams => null.
• due_date → resolve per rules above; if not resolvable, null with a brief explanation.
• confidence ∈ [0,1] reflects certainty of classification and extracted fields.
• explanations → brief bullets for assumptions, heuristics, or missing info; null if not needed.
"""

_llm_instance = None

def get_llm():
    """Get or create LLM instance (singleton for performance)"""
    global _llm_instance
    if _llm_instance is None and LANGCHAIN_AVAILABLE:
        _llm_instance = ChatOpenAI(
            model=OPENAI_MODEL,
            temperature=0,
            timeout=20.0,
            max_retries=0
        )
    return _llm_instance

def classify_message(message: str, message_timestamp: Optional[str] = None):
    """
    Classify a message using LangChain structured output

    Returns:
        ClassificationV1: Validated classification result
    """
    if not LANGCHAIN_AVAILABLE or not PYDANTIC_AVAILABLE:
        raise ImportError("LangChain and Pydantic are required for classification")

    llm = get_llm()
    if llm is None:
        raise ValueError("Failed to initialize LLM")

    # Use LangChain's with_structured_output for native structured output
    structured_llm = llm.with_structured_output(ClassificationV1)

    # Build prompt with timestamp context
    user_message = message
    if message_timestamp:
        user_message = f"Message timestamp: {message_timestamp}\n\nMessage: {message}"

    # Invoke with system + user messages
    result = structured_llm.invoke([
        {"role": "system", "content": CLASSIFICATION_INSTRUCTIONS},
        {"role": "user", "content": user_message}
    ])

    return result


# ============================================================================
# SUPABASE CLIENT
# ============================================================================

_supabase_client = None

def get_supabase():
    """Get or create Supabase client (singleton)"""
    global _supabase_client
    if _supabase_client is None and SUPABASE_AVAILABLE:
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise ValueError("Missing SUPABASE_URL or SUPABASE_KEY environment variables")
        _supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _supabase_client


# ============================================================================
# WEBHOOK HANDLER
# ============================================================================

class handler(BaseHTTPRequestHandler):
    """Vercel serverless function handler for Slack Events API"""

    def do_POST(self):
        try:
            print("📥 Incoming POST request")
            print(f"   SLACK_BYPASS_VERIFY: {SLACK_BYPASS_VERIFY}")

            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            raw_body = self.rfile.read(content_length).decode('utf-8')

            # Verify signature (unless bypassed for local development)
            if not SLACK_BYPASS_VERIFY:
                print("🔒 Signature verification is ENABLED")
                signature = self.headers.get('X-Slack-Signature', '')
                timestamp = self.headers.get('X-Slack-Request-Timestamp', '')
                print(f"   Signature header: {'present' if signature else 'missing'}")
                print(f"   Timestamp header: {'present' if timestamp else 'missing'}")

                if not verify_slack_signature(SLACK_SIGNING_SECRET, timestamp, raw_body, signature):
                    print("❌ Signature verification FAILED")
                    self.send_json_response(401, {"ok": False, "error": "Invalid signature"})
                    return
                print("✅ Signature verification PASSED")
            else:
                print("⚠️  Signature verification is BYPASSED")

            # Parse JSON body
            try:
                body = json.loads(raw_body)
            except json.JSONDecodeError:
                self.send_json_response(400, {"ok": False, "error": "Invalid JSON"})
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

                # Process event
                if event_type in ['app_mention', 'message']:
                    self._process_slack_event(event, body.get('event_id'))

                return

            # Unknown event type (acknowledge it anyway)
            self.send_json_response(200, {'ok': True})

        except Exception as e:
            print(f"Error processing Slack webhook: {e}")
            import traceback
            traceback.print_exc()
            self.send_json_response(500, {"ok": False, "error": f"Internal server error: {str(e)}"})

    def _process_slack_event(self, event: dict, event_id: str):
        """Process Slack message event using LangChain classifier and save to Supabase"""
        message_text = event.get('text', '')
        user_id = event.get('user', '')
        channel_id = event.get('channel', '')
        ts = event.get('ts', '')

        if not message_text:
            return

        print(f"📨 Message received from {user_id} in {channel_id}")
        print(f"   Text: {message_text[:100]}...")

        try:
            # Classify message using LangChain
            classification = classify_message(message_text, message_timestamp=ts)

            print(f"✅ Classification complete:")
            print(f"   Message type: {classification.message_type.value}")
            print(f"   Confidence: {classification.confidence}")

            # Save to Supabase
            if SUPABASE_AVAILABLE:
                supabase = get_supabase()

                try:
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
                    print(f"💾 Saved to Supabase: {classification_id}")

                    # Log to audit_log (only on successful new insert)
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
                        print(f"⚠️  Audit log failed (non-critical): {audit_error}")

                except Exception as db_error:
                    # Handle duplicate event_id (Slack retry) - this is normal and expected
                    error_dict = getattr(db_error, 'args', [{}])[0] if hasattr(db_error, 'args') else {}
                    if isinstance(error_dict, dict) and error_dict.get('code') == '23505':
                        print(f"ℹ️  Event {event_id} already processed (Slack retry) - skipping")
                        return  # Successfully handled - no need to process again
                    else:
                        # Re-raise if it's a different error
                        raise
            else:
                print("⚠️  Supabase not available - classification not saved")

        except Exception as e:
            print(f"❌ Error classifying message: {e}")
            import traceback
            traceback.print_exc()

    def send_json_response(self, status_code: int, data: dict):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def send_text_response(self, status_code: int, text: str):
        """Send plain text response"""
        self.send_response(status_code)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(text.encode())
