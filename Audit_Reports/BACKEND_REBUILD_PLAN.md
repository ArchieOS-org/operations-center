# Backend Rebuild: Simplified LangChain Implementation Plan

**Created:** 2025-01-16
**Status:** Planning Complete - Ready for Implementation
**Branch:** `nsd97/audit-quality-gaps`

---

## Executive Summary

Rebuild the Vercel Python backend with a **radically simplified** LangChain implementation that handles rapid consecutive messages intelligently. The system will:

1. **Batch consecutive messages** from the same user automatically
2. **Classify** with existing proven prompts (reuse, don't rebuild)
3. **Store** in Supabase with exact variable names matching Swift frontend
4. **Acknowledge** via Slack only when tasks/listings detected
5. **Auto-create activities** for listings based on type

**Core Philosophy:** Delete complexity. Ship intelligence.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SLACK MESSAGE FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

1. Slack Event → POST /webhooks/slack
                   ↓
2. Smart Message Queue (NEW)
   - Detects burst from same user/channel
   - Accumulates messages for 2 seconds
   - Batches together
                   ↓
3. LLM Classification (EXISTING - reuse prompt)
   - Uses proven ClassificationV1 prompt
   - Returns structured JSON
                   ↓
4. Store in slack_messages table
   - Exact column names from migrations
                   ↓
5. JSON Processor (NEW)
   - Creates listing OR agent_task
   - Auto-attaches activities to listings
                   ↓
6. Slack Acknowledgment (NEW)
   - "✅ Task detected!" (if task)
   - "🏠 Listing detected: [type]" (if listing)
   - Silent (if neither)
                   ↓
7. Return 200 OK to Slack (within 3s timeout)
```

---

## What Changes vs. What Stays

### ✅ KEEP (Working Code)

1. **Classification Prompt** (`app/agents/classifier.py` lines 19-103)
   - Proven, tuned, working
   - ClassificationV1 schema is solid
   - DO NOT TOUCH

2. **Database Schema** (all migrations)
   - Every table name EXACT
   - Every column name EXACT
   - Frontend depends on this

3. **Supabase Client** (`app/database/supabase_client.py`)
   - Singleton pattern works
   - Reuse as-is

4. **Settings/Config** (`app/config/settings.py`)
   - Environment loading works
   - Keep unchanged

5. **Slack Signature Verification** (`app/utils/slack_verify.py`)
   - Security is critical
   - Keep as-is

### ❌ REPLACE (Add Smart Queue)

1. **Slack Webhook Handler** (`app/main.py` lines 122-171)
   - Add queue detection logic
   - Add batching timeout

2. **Slack Intake Workflow** (`app/workflows/slack_intake.py`)
   - Simplify graph
   - Remove unnecessary nodes
   - Focus on: validate → queue → batch → classify → store → process → acknowledge

3. **Entity Creation** (`app/workflows/entity_creation.py`)
   - Add activities auto-creation
   - Match exact column names

### ➕ ADD (New Components)

1. **Smart Message Queue** (new file)
   - In-memory queue with Redis-like interface
   - Detect bursts from same user/channel
   - 2-second accumulation window
   - Batch output

2. **Slack Acknowledgment System** (new file)
   - WebClient integration
   - Post to channel based on classification
   - Thread support (optional)

3. **Activities Auto-Creation Logic**
   - Check listing type
   - Attach predefined activities
   - Store in activities table

---

## Implementation Details

### Component 1: Smart Message Queue

**File:** `app/queue/message_queue.py` (NEW)

**Purpose:** Accumulate rapid consecutive messages from same user/channel, batch them together after timeout.

**Data Structure:**
```python
{
    "queue_key": "user_id:channel_id",  # Composite key
    "messages": [
        {
            "event": {...},           # Full Slack event
            "received_at": datetime,
            "text": "message content"
        }
    ],
    "timer": asyncio.Task,  # 2-second timeout
    "status": "accumulating" | "processing"
}
```

**Logic:**
1. Message arrives → Check if queue exists for `user_id:channel_id`
2. If yes and status == "accumulating":
   - Cancel existing timer
   - Append message to queue
   - Start new 2-second timer
3. If no or status == "processing":
   - Create new queue
   - Start 2-second timer
4. On timer expiry:
   - Batch all messages together
   - Send to classifier as single input
   - Mark queue status = "processing"
   - Delete queue after processing

**Key Functions:**
```python
async def enqueue_message(user_id: str, channel_id: str, event: dict) -> None
async def process_queue(queue_key: str) -> None  # Called by timer
async def get_batched_messages(queue_key: str) -> List[dict]
```

**LangChain Pattern:** Use `@before_model` middleware to batch messages
- From Context7: `trim_messages`, `delete_old_messages` patterns
- Adapt for our use case: batch instead of trim

---

### Component 2: Revised Slack Webhook Handler

**File:** `app/main.py` (MODIFY)

**Current Issues:**
- No message batching
- Processes every message immediately
- Duplicate processing for rapid messages

**New Logic:**
```python
@app.post("/webhooks/slack")
async def slack_webhook(payload: SlackWebhookPayload, request: Request):
    """Handles Slack Events API callbacks with smart queueing"""

    # 1. URL verification (keep as-is)
    if payload.type == "url_verification":
        return {"challenge": payload.challenge}

    # 2. Event callback - NEW LOGIC
    if payload.type == "event_callback":
        event = payload.event

        # Skip bots (keep)
        if event.get("bot_id") or event.get("subtype") == "bot_message":
            return {"ok": True}

        # Extract identifiers
        user_id = event.get("user")
        channel_id = event.get("channel")

        # NEW: Enqueue instead of immediate processing
        await enqueue_message(user_id, channel_id, event)

        # Return 200 immediately (Slack 3s timeout requirement)
        return {"ok": True}
```

**Key Changes:**
- Remove direct `process_slack_message()` call
- Add `enqueue_message()` call
- Queue handles batching and timer
- Timer triggers `process_batched_messages()` after 2s

---

### Component 3: Batched Classification

**File:** `app/workflows/batched_classification.py` (NEW)

**Purpose:** Process batched messages as single classification input

**Input:** List of messages from same user/channel
```python
messages = [
    {"text": "List this property at 123 Main St", "ts": "1.1"},
    {"text": "It's a 3 bed 2 bath", "ts": "1.2"},
    {"text": "Sale price $500k", "ts": "1.3"}
]
```

**Approach:** Concatenate with context
```python
def batch_messages_for_classification(messages: List[dict]) -> str:
    """Combine multiple messages into single classification input"""

    if len(messages) == 1:
        return messages[0]["text"]

    # Combine with timestamps for context
    combined = "User sent the following messages in quick succession:\n\n"
    for msg in messages:
        combined += f"[{msg['ts']}] {msg['text']}\n"

    combined += "\nClassify these as a single unit (they are related)."

    return combined
```

**Classification:** Use existing `MessageClassifier` agent
- Input: Batched text
- Output: Single ClassificationV1 result
- Store: Link to ALL message timestamps

---

### Component 4: Slack Acknowledgment System

**File:** `app/services/slack_client.py` (NEW)

**Purpose:** Post acknowledgment messages back to Slack channel

**Setup:**
```python
from slack_sdk import WebClient
from app.config.settings import get_settings

settings = get_settings()
slack_client = WebClient(token=settings.SLACK_BOT_TOKEN)
```

**Functions:**
```python
async def send_task_acknowledgment(
    channel: str,
    thread_ts: Optional[str] = None
) -> None:
    """Send task detection acknowledgment"""
    slack_client.chat_postMessage(
        channel=channel,
        text="✅ Task detected and added to your queue!",
        thread_ts=thread_ts  # Reply in thread if applicable
    )

async def send_listing_acknowledgment(
    channel: str,
    listing_type: str,
    address: str,
    thread_ts: Optional[str] = None
) -> None:
    """Send listing detection acknowledgment"""
    slack_client.chat_postMessage(
        channel=channel,
        text=f"🏠 Listing detected: {listing_type} - {address}",
        thread_ts=thread_ts
    )

async def send_acknowledgment(
    classification: ClassificationV1,
    channel: str,
    thread_ts: Optional[str] = None
) -> None:
    """Router function - sends appropriate acknowledgment"""

    if classification.message_type == MessageType.GROUP:
        await send_listing_acknowledgment(
            channel=channel,
            listing_type=classification.group_key.value,
            address=classification.listing.address,
            thread_ts=thread_ts
        )
    elif classification.message_type == MessageType.STRAY:
        await send_task_acknowledgment(
            channel=channel,
            thread_ts=thread_ts
        )
    # IGNORE and INFO_REQUEST: no acknowledgment (silent)
```

**Integration Point:** Call after entity creation succeeds
- If listing created → send listing ack
- If task created → send task ack
- If neither → silent

---

### Component 5: Activities Auto-Creation

**File:** `app/workflows/entity_creation.py` (MODIFY)

**Current:** Creates listing record only

**New:** Create listing + auto-attach activities based on type

**Activities Mapping:**
```python
LISTING_ACTIVITIES = {
    "SALE_LISTING": [
        {"name": "Take listing photos", "priority": 100, "category": "MARKETING"},
        {"name": "Create MLS listing", "priority": 90, "category": "ADMIN"},
        {"name": "Schedule open house", "priority": 80, "category": "MARKETING"},
        {"name": "Order yard sign", "priority": 70, "category": "MARKETING"},
    ],
    "LEASE_LISTING": [
        {"name": "Schedule showings", "priority": 100, "category": "ADMIN"},
        {"name": "Prepare lease agreement", "priority": 90, "category": "ADMIN"},
        {"name": "Background check applicants", "priority": 80, "category": "ADMIN"},
    ],
    # ... more mappings
}
```

**Implementation:**
```python
async def create_listing_with_activities(
    classification: ClassificationV1,
    realtor_id: Optional[str],
    message_text: str
) -> Optional[str]:
    """Creates listing + auto-attached activities"""

    # 1. Create listing (existing logic)
    listing_id = await create_listing_record(
        classification=classification,
        realtor_id=realtor_id,
        message_text=message_text
    )

    if not listing_id:
        return None

    # 2. NEW: Auto-create activities based on group_key
    group_key = classification.group_key.value
    activities_template = LISTING_ACTIVITIES.get(group_key, [])

    for activity in activities_template:
        await create_activity_record(
            listing_id=listing_id,
            realtor_id=realtor_id,
            name=activity["name"],
            priority=activity["priority"],
            task_category=activity["category"],
            status="OPEN",
            visibility_group="BOTH"
        )

    return listing_id

async def create_activity_record(
    listing_id: str,
    realtor_id: Optional[str],
    name: str,
    priority: int,
    task_category: str,
    status: str,
    visibility_group: str
) -> Optional[str]:
    """Insert into activities table with EXACT column names"""

    from uuid import uuid4
    from datetime import datetime, timezone

    activity_data = {
        "task_id": str(uuid4()),           # PRIMARY KEY
        "listing_id": listing_id,          # FK to listings
        "realtor_id": realtor_id,          # FK to realtors (nullable)
        "name": name,                      # NOT NULL
        "description": None,               # Optional
        "task_category": task_category,    # ADMIN | MARKETING | NULL
        "status": status,                  # OPEN | CLAIMED | etc.
        "priority": priority,              # 0-10
        "visibility_group": visibility_group,  # BOTH | AGENT | MARKETING
        "assigned_staff_id": None,         # Unassigned initially
        "due_date": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

    try:
        response = await supabase.table("activities").insert(activity_data).execute()
        return activity_data["task_id"]
    except Exception as e:
        logger.error(f"Failed to create activity: {e}")
        return None
```

**CRITICAL:** Column names MUST match database EXACTLY
- `task_id` NOT `activity_id` (primary key)
- `task_category` NOT `category`
- `visibility_group` NOT `visibility`
- All snake_case

---

### Component 6: Simplified Workflow Graph

**File:** `app/workflows/slack_intake.py` (MODIFY)

**Current Graph:** 7 nodes (validate, classify, store, create_entities, route, respond, error)

**New Graph:** 5 nodes (validate, classify, store, process, acknowledge)

```python
from langgraph.graph import StateGraph, END, START
from typing_extensions import TypedDict

class SlackIntakeState(TypedDict):
    """State for simplified intake workflow"""
    messages: List[dict]           # Batched messages from queue
    user_id: str
    channel_id: str
    classification: Optional[ClassificationV1]
    created_entity_id: Optional[str]
    created_entity_type: Optional[str]  # "listing" | "agent_task"
    error: Optional[str]

def build_intake_workflow() -> StateGraph:
    workflow = StateGraph(SlackIntakeState)

    # Nodes
    workflow.add_node("validate", validate_messages)
    workflow.add_node("classify", classify_batched_messages)
    workflow.add_node("store", store_classification)
    workflow.add_node("process", create_entities)
    workflow.add_node("acknowledge", send_slack_ack)

    # Edges
    workflow.add_edge(START, "validate")
    workflow.add_edge("validate", "classify")
    workflow.add_edge("classify", "store")
    workflow.add_edge("store", "process")
    workflow.add_edge("process", "acknowledge")
    workflow.add_edge("acknowledge", END)

    return workflow.compile()

async def validate_messages(state: SlackIntakeState) -> dict:
    """Skip bots, validate structure"""
    # Keep existing validation logic
    pass

async def classify_batched_messages(state: SlackIntakeState) -> dict:
    """Call MessageClassifier with batched text"""
    messages = state["messages"]
    combined_text = batch_messages_for_classification(messages)

    classifier = MessageClassifier()
    result = await classifier.process({"message": combined_text})

    return {"classification": result["classification"]}

async def store_classification(state: SlackIntakeState) -> dict:
    """Insert into slack_messages table"""
    # Store with EXACT column names
    # Link to ALL message timestamps
    pass

async def create_entities(state: SlackIntakeState) -> dict:
    """Create listing or agent_task + activities"""
    classification = state["classification"]

    if classification.message_type == MessageType.GROUP:
        entity_id = await create_listing_with_activities(...)
        entity_type = "listing"
    elif classification.message_type == MessageType.STRAY:
        entity_id = await create_agent_task_record(...)
        entity_type = "agent_task"
    else:
        entity_id = None
        entity_type = None

    return {
        "created_entity_id": entity_id,
        "created_entity_type": entity_type
    }

async def send_slack_ack(state: SlackIntakeState) -> dict:
    """Send acknowledgment to Slack if entity created"""
    if state["created_entity_id"]:
        await send_acknowledgment(
            classification=state["classification"],
            channel=state["channel_id"],
            thread_ts=state["messages"][0].get("thread_ts")
        )
    return {}
```

**Key Simplifications:**
- Remove "route" node (no orchestrator needed)
- Remove "respond" node (acknowledgment handles this)
- Remove "error" node (let FastAPI handle errors)
- Linear flow: validate → classify → store → process → acknowledge → done

---

## Database Operations

### Table: `slack_messages`

**Columns to populate:**
```python
{
    "message_id": str(ULID()),                    # Auto-generated
    "slack_user_id": event["user"],               # From Slack
    "slack_channel_id": event["channel"],         # From Slack
    "slack_ts": event["ts"],                      # Message timestamp
    "slack_thread_ts": event.get("thread_ts"),    # Thread (optional)
    "message_text": combined_text,                # Batched text
    "classification": classification.model_dump(),# Full JSON
    "message_type": classification.message_type.value,
    "task_key": classification.task_key.value if classification.task_key else None,
    "group_key": classification.group_key.value if classification.group_key else None,
    "confidence": float(classification.confidence),
    "created_listing_id": listing_id,             # If listing created
    "created_task_id": task_id,                   # If task created
    "created_task_type": "listing_task" or "stray_task",
    "received_at": datetime.utcnow().isoformat(),
    "processed_at": datetime.utcnow().isoformat(),
    "processing_status": "processed",
    "error_message": None,
}
```

### Table: `listings`

**Columns to populate:**
```python
{
    "listing_id": str(uuid4()),
    "address_string": classification.listing.address or "Unknown",
    "type": classification.listing.type.value,  # SALE | LEASE
    "status": "new",
    "assignee": realtor_id,
    "agent_id": realtor_id,
    "realtor_id": realtor_id,
    "due_date": classification.due_date,
    "progress": 0.0,
    "created_at": datetime.utcnow().isoformat(),
    "updated_at": datetime.utcnow().isoformat(),
}
```

### Table: `agent_tasks`

**Columns to populate:**
```python
{
    "task_id": str(uuid4()),
    "realtor_id": realtor_id,
    "task_key": classification.task_key.value,
    "name": classification.task_title or "Untitled Task",
    "description": message_text,
    "task_category": None,  # Set later by staff
    "status": "OPEN",
    "priority": 5,
    "due_date": classification.due_date,
    "created_at": datetime.utcnow().isoformat(),
    "updated_at": datetime.utcnow().isoformat(),
}
```

### Table: `activities`

**Columns to populate:**
```python
{
    "task_id": str(uuid4()),               # PRIMARY KEY
    "listing_id": listing_id,              # FK to listings
    "realtor_id": realtor_id,              # FK to realtors
    "name": "Activity Name",
    "description": None,
    "task_category": "ADMIN" or "MARKETING",
    "status": "OPEN",
    "priority": 100,  # Higher = more urgent
    "visibility_group": "BOTH",  # BOTH | AGENT | MARKETING
    "assigned_staff_id": None,
    "due_date": None,
    "created_at": datetime.utcnow().isoformat(),
    "updated_at": datetime.utcnow().isoformat(),
}
```

---

## Environment Variables

**Required (already in settings.py):**
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`
- `OPENAI_API_KEY`
- `SLACK_SIGNING_SECRET`

**NEW - Add to settings.py:**
- `SLACK_BOT_TOKEN` - For posting acknowledgments via WebClient

**Add to `.env.example`:**
```bash
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
```

**Add to `app/config/settings.py`:**
```python
SLACK_BOT_TOKEN: str  # Required for acknowledgments
```

---

## File Structure (New + Modified)

```
app/
├── queue/                          # NEW DIRECTORY
│   ├── __init__.py
│   └── message_queue.py           # NEW: Smart queue with batching
│
├── services/                       # NEW DIRECTORY
│   ├── __init__.py
│   └── slack_client.py            # NEW: Slack acknowledgments
│
├── workflows/
│   ├── __init__.py
│   ├── slack_intake.py            # MODIFY: Simplified 5-node graph
│   ├── entity_creation.py         # MODIFY: Add activities auto-creation
│   └── batched_classification.py  # NEW: Batch message handling
│
├── agents/
│   ├── __init__.py
│   └── classifier.py              # KEEP: Reuse existing prompt
│
├── config/
│   ├── __init__.py
│   └── settings.py                # MODIFY: Add SLACK_BOT_TOKEN
│
├── main.py                         # MODIFY: Update webhook handler
│
└── ... (rest unchanged)
```

---

## Implementation Sequence

### Phase 1: Foundation (Day 1)
1. Create `app/queue/message_queue.py`
   - In-memory queue implementation
   - 2-second batching logic
   - Test with mock messages

2. Create `app/services/slack_client.py`
   - WebClient setup
   - Acknowledgment functions
   - Test posting to dev channel

3. Update `app/config/settings.py`
   - Add `SLACK_BOT_TOKEN`
   - Validate environment loading

### Phase 2: Workflow Rebuild (Day 2)
4. Create `app/workflows/batched_classification.py`
   - Message batching formatter
   - Test with classifier agent

5. Modify `app/workflows/slack_intake.py`
   - Simplify to 5 nodes
   - Integrate batching
   - Remove orchestrator dependency

6. Modify `app/workflows/entity_creation.py`
   - Add `LISTING_ACTIVITIES` mapping
   - Implement `create_listing_with_activities()`
   - Implement `create_activity_record()`
   - Test activities table insertion

### Phase 3: Integration (Day 3)
7. Modify `app/main.py`
   - Update `/webhooks/slack` handler
   - Integrate message queue
   - Remove direct workflow call
   - Add queue timer trigger

8. End-to-End Testing
   - Send single message → verify classification
   - Send 3 rapid messages → verify batching
   - Verify listing created with activities
   - Verify task created
   - Verify Slack acknowledgments posted

### Phase 4: Deployment (Day 4)
9. Update `requirements.txt`
   - Add `slack-sdk>=3.27.0` (currently commented)

10. Deploy to Vercel
    - Set `SLACK_BOT_TOKEN` in Vercel env vars
    - Deploy via `git push`
    - Monitor logs for errors

11. Production Testing
    - Point Slack webhook to new endpoint
    - Test with real messages
    - Monitor error rates

---

## Testing Strategy

### Unit Tests
```python
# test_message_queue.py
async def test_single_message_immediate_processing():
    """Single message should process after 2s"""
    pass

async def test_rapid_messages_batched():
    """3 messages in 1s should batch together"""
    pass

async def test_different_users_separate_queues():
    """Messages from different users don't batch"""
    pass
```

### Integration Tests
```python
# test_slack_intake.py
async def test_batched_classification():
    """Batched messages produce single classification"""
    pass

async def test_listing_with_activities():
    """Listing creation auto-creates activities"""
    pass

async def test_slack_acknowledgment():
    """Acknowledgment posted to correct channel"""
    pass
```

### Manual Testing Checklist
- [ ] Single message → task created → acknowledgment posted
- [ ] Single message → listing created → acknowledgment posted → activities created
- [ ] 3 rapid messages → batched → single classification → single entity
- [ ] Message with "IGNORE" classification → no acknowledgment
- [ ] Message with "INFO_REQUEST" → no acknowledgment
- [ ] Different users rapid messages → separate processing
- [ ] Same user, different channels → separate processing

---

## Success Criteria

1. **Batching Works**
   - 3+ messages from same user in <2s batch together
   - Single classification result from batch
   - No duplicate entity creation

2. **Exact Variable Names**
   - All database inserts use snake_case column names
   - Swift app can query without errors
   - No type mismatches

3. **Activities Auto-Create**
   - Listing creation triggers activity creation
   - Activities table populated correctly
   - Frontend displays activities immediately

4. **Slack Acknowledgments**
   - Posted within 1s of entity creation
   - Correct message format
   - Threaded replies work

5. **Performance**
   - Slack webhook responds within 3s
   - Classification completes within 10s
   - No timeout errors

---

## Rollback Plan

If issues arise in production:

1. **Immediate:** Revert Vercel deployment to previous version
2. **Disable:** Set `SLACK_BYPASS_VERIFY=true` to pause webhook
3. **Diagnose:** Check Vercel logs for errors
4. **Fix:** Deploy hotfix or roll back to previous stable version
5. **Re-enable:** Remove bypass flag, resume processing

---

## Dependencies

**Python Packages (add to requirements.txt):**
```txt
slack-sdk>=3.27.0  # For WebClient acknowledgments
```

**Already Installed:**
- `langchain>=0.3.0`
- `supabase>=2.10.0`
- `fastapi>=0.115.13`
- `pydantic>=2.9.2`

---

## Open Questions

1. **Queue Persistence:** Should queue survive server restarts?
   - **Decision:** No - in-memory is fine for MVP. Messages will reprocess on restart.

2. **Batch Size Limit:** Max messages per batch?
   - **Decision:** 10 messages max. Beyond that, process as separate batches.

3. **Timeout Tuning:** 2 seconds optimal?
   - **Decision:** Start with 2s, monitor in production, adjust if needed.

4. **Activities Templates:** Where to store templates?
   - **Decision:** Python dict in `entity_creation.py` for MVP. Move to database later.

5. **Acknowledgment Threading:** Always thread or main channel?
   - **Decision:** Main channel for MVP. Add threading config later.

---

## Migration Notes

**From Old Code:**
- Keep all existing database migrations
- Keep all existing Pydantic models
- Keep classification prompt EXACTLY as-is
- Archive old workflows to `trash/workflows-archive-20250116/`

**Variable Name Mappings (CRITICAL):**
- Database uses `snake_case` (e.g., `task_id`, `listing_id`)
- Swift uses `camelCase` but CodingKeys map to `snake_case`
- Backend MUST return exact `snake_case` from database
- Frontend handles the mapping via CodingKeys

**Testing with Frontend:**
1. Deploy backend to Vercel
2. Update Swift app Xcode scheme env var `FASTAPI_URL`
3. Build iOS app: `xcodebuild -scheme "Operations Center" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build -quiet`
4. Test end-to-end flow from Slack → Backend → Supabase → Swift app

---

## Post-Implementation Tasks

1. **Documentation:**
   - Update README with new queue architecture
   - Document activities templates for each listing type
   - Create runbook for tuning batch timeout

2. **Monitoring:**
   - Add logging for queue sizes
   - Track batch processing times
   - Monitor classification success rates

3. **Optimization:**
   - Consider Redis for queue persistence (if needed)
   - Add retry logic for failed Slack posts
   - Implement rate limiting (if needed)

4. **Future Enhancements:**
   - Store activities templates in database
   - Add threading config for acknowledgments
   - Support SMS webhook (currently stubbed)
   - Add background workers for long-running tasks

---

## Summary

This plan rebuilds the backend with these principles:

1. **Simplicity:** Remove orchestrator, remove routing complexity
2. **Reuse:** Keep proven classification prompt, keep working schema
3. **Intelligence:** Smart batching prevents duplicate processing
4. **Exactness:** Match frontend variable names EXACTLY
5. **Feedback:** Acknowledge to users immediately

**Result:** A radically simplified backend that does one thing perfectly - classifies messages and creates entities intelligently.

Delete complexity. Ship intelligence.
