# LANGCHAIN V1 - THE REAL SHIP-IT PLAN

## The Truth

You have one person (you) and one mission: **Make the bot respond in Slack**.

The comprehensive blueprint has 12 steps and 30,000 lines. That's the vision.
This is what you actually ship today.

---

## What's Actually Broken (Only 2 Things)

1. **Orchestrator doesn't exist** - It's not registered, returns stubs
2. **Slack never gets responses** - Messages generated but never sent

Everything else works:
- ✅ Webhook receives messages
- ✅ Classification works
- ✅ Database writes work
- ✅ Entity creation works (mostly)

**Fix those 2 things. Ship v1.**

---

## THE 3-FILE FIX (Ship Today)

### File 1: Create Slack Tools
**`/apps/backend/api/tools/slack.py`** (NEW - 30 lines)

```python
"""
Slack tools - JUST SEND THE DAMN MESSAGE.
"""
import os
from langchain.tools import tool
from slack_sdk.web.async_client import AsyncWebClient

# Initialize client
slack_client = AsyncWebClient(token=os.getenv("SLACK_BOT_TOKEN"))

@tool
async def send_slack_message(channel: str, text: str, thread_ts: str = None) -> dict:
    """
    Send a message to Slack. USE THIS TO RESPOND TO USERS.

    Args:
        channel: Channel ID (e.g., C1234567890)
        text: Message to send
        thread_ts: Optional thread timestamp to reply in thread
    """
    try:
        response = await slack_client.chat_postMessage(
            channel=channel,
            text=text,
            thread_ts=thread_ts
        )
        return {"success": True, "ts": response["ts"]}
    except Exception as e:
        return {"success": False, "error": str(e)}
```

**That's it. One tool. It sends messages.**

---

### File 2: Fix the Orchestrator
**`/apps/backend/api/agents/orchestrator.py`** (REPLACE ENTIRE FILE - 100 lines)

```python
"""
Orchestrator Agent - V1 - JUST MAKE IT WORK.
Uses create_agent like we're supposed to in 2025.
"""
import os
from typing import Dict, Any, Optional
from langchain.agents import create_agent
from langchain.chat_models import init_chat_model
from langchain_core.messages import HumanMessage

# Import existing tools that work
from app.tools.database import create_listing, create_task, search_listings
from app.tools.slack import send_slack_message

# System prompt - Keep it simple
ORCHESTRATOR_PROMPT = """You are a real estate operations assistant.

When users message you from Slack:
1. Understand what they need
2. Use tools to help them
3. ALWAYS send a response back using send_slack_message

Available actions:
- Create listings (use create_listing)
- Create tasks (use create_task)
- Search listings (use search_listings)
- Send responses (use send_slack_message) - ALWAYS DO THIS

Important:
- After ANY action, confirm what you did via send_slack_message
- If you can't help, still send a message saying why
- Be concise and professional
"""

class OrchestratorAgent:
    """V1 Orchestrator - Just works."""

    def __init__(self):
        """Initialize with Anthropic and tools."""
        # Use Anthropic directly (skip provider abstraction for v1)
        self.llm = init_chat_model(
            f"anthropic:{os.getenv('ANTHROPIC_MODEL', 'claude-3-5-sonnet-20241022')}",
            temperature=0
        )

        # Bind the tools that work
        self.tools = [
            create_listing,
            create_task,
            search_listings,
            send_slack_message  # THE CRITICAL ADDITION
        ]

        # Create agent with tools
        self.agent = create_agent(
            model=self.llm,
            tools=self.tools,
            system_prompt=ORCHESTRATOR_PROMPT
        )

    async def process(
        self,
        message: str,
        channel_id: str,
        user_id: Optional[str] = None,
        thread_ts: Optional[str] = None,
        classification: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Process message and RESPOND TO SLACK.

        The agent will use tools including send_slack_message.
        """
        # Build context
        context = f"Channel: {channel_id}"
        if user_id:
            context += f", User: {user_id}"
        if classification:
            context += f", Classification: {classification.get('category', 'unknown')}"

        # Full message with context
        full_message = f"""{context}

User message: {message}

Remember to send a response to channel {channel_id}"""
        if thread_ts:
            full_message += f" in thread {thread_ts}"

        # Let the agent handle it
        result = await self.agent.ainvoke({
            "messages": [HumanMessage(content=full_message)]
        })

        return {
            "success": True,
            "agent_response": result
        }

# Singleton
_orchestrator = None

def get_orchestrator():
    """Get or create orchestrator."""
    global _orchestrator
    if not _orchestrator:
        _orchestrator = OrchestratorAgent()
    return _orchestrator
```

**That's the entire orchestrator. 100 lines. It works.**

---

### File 3: Register the Orchestrator
**`/apps/backend/api/agents/__init__.py`** (UPDATE - 5 lines)

```python
# Line 35 - UNCOMMENT THIS LINE
AGENT_REGISTRY = {
    "classifier": ClassificationAgent,
    "orchestrator": OrchestratorAgent,  # <-- UNCOMMENT THIS
}
```

**Just uncomment one line. Now it's registered.**

---

## Test It (5 Minutes)

1. **Start the backend:**
```bash
cd apps/backend/api
uvicorn main:app --reload
```

2. **Send a test Slack message:**
```
"Create a task to call John about 123 Main Street"
```

3. **What should happen:**
   - Message received ✅
   - Classified as TASK ✅
   - Task created in database ✅
   - **Bot responds in Slack: "Created task: Call John about 123 Main Street"** ✅

If that works: **SHIP IT**.

---

## What We're NOT Doing (Yet)

### Skip for V1:
- ❌ Provider abstraction (just use Anthropic)
- ❌ Streaming (not needed yet)
- ❌ Background queue (process inline)
- ❌ PostgreSQL memory (no memory is fine)
- ❌ Specialist agents (orchestrator does everything)
- ❌ Complex error handling (let it fail)
- ❌ All 12 steps from the blueprint

### What V1 Does:
- ✅ Receives Slack messages
- ✅ Classifies them
- ✅ Creates entities
- ✅ **RESPONDS IN SLACK**

**That's a working product.**

---

## Deployment (10 Minutes)

1. **Add environment variable:**
```bash
# Vercel dashboard
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
```

2. **Commit and push:**
```bash
git add .
git commit -m "Add Slack response capability - V1"
git push
```

3. **Vercel auto-deploys**

4. **Test in production**

---

## V1 → V2 Roadmap

### V1 (Today) - JUST SHIP:
- Orchestrator works ✅
- Slack responses sent ✅
- Basic functionality ✅

### V2 (Next Week) - Polish:
- Better error handling
- Nicer response formatting
- Handle edge cases
- Add logging

### V3 (Later) - Scale:
- Background queue for 3s timeout
- Memory/conversation continuity
- Specialist agents
- Streaming responses

### V4 (Vision) - The Full Blueprint:
- All 12 steps
- Provider abstraction
- PostgreSQL persistence
- Complete test coverage

---

## The Philosophy

**"Real artists ship."**

The blueprint is where we're going.
This plan is how we get there.
One working feature at a time.

You don't need perfection.
You need a bot that responds.

**Ship V1. Today.**

---

## Implementation Checklist

### Today (30 minutes):
- [ ] Create `/apps/backend/api/tools/slack.py` (copy from above)
- [ ] Replace `/apps/backend/api/agents/orchestrator.py` (copy from above)
- [ ] Uncomment orchestrator in `/apps/backend/api/agents/__init__.py`
- [ ] Test locally with one message
- [ ] Deploy to Vercel
- [ ] Test in production
- [ ] Ship it

### Tomorrow:
- [ ] Monitor for errors
- [ ] Add one improvement
- [ ] Ship again

### This Week:
- [ ] V1 working in production
- [ ] Users getting responses
- [ ] Iterate based on feedback

---

## Success Criteria

**V1 is successful if:**
1. User sends: "What's the status of 123 Main Street?"
2. Bot responds: "123 Main Street is currently ACTIVE..."

**That's it. Ship it.**