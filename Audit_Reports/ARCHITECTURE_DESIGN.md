# Operations Center - Agent Architecture Design
*A Steve Jobs-Inspired Structure*

## Core Principle
**"Every file should have a purpose. Every directory should tell a story."**

The architecture should be so clear that a new developer understands the entire system in 30 seconds.

## The Architecture - Visual Clarity

```
operations-center/
├── 🧠 apps/backend/api/              # THE INTELLIGENCE LAYER (FastAPI on Vercel)
│   │
│   ├── 🤖 agents/                    # THE MINDS - Each agent is a specialist
│   │   ├── __init__.py               # Agent registry and discovery
│   │   ├── orchestrator.py           # 🎼 The Conductor - Routes all messages
│   │   ├── classifier.py             # 🏷️ The Interpreter - Understands intent
│   │   ├── realtor_agent.py          # 🏡 The Realtor Expert - All things realtor
│   │   ├── listing_agent.py          # 🏠 The Property Expert - Listing management
│   │   ├── task_agent.py             # ✅ The Task Master - Work distribution
│   │   └── notification_agent.py     # 📬 The Messenger - Slack/SMS/Email
│   │
│   ├── 🛠️ tools/                     # THE CAPABILITIES - Reusable functions
│   │   ├── __init__.py               # Tool registry
│   │   ├── database.py               # 💾 Database operations (Supabase writes)
│   │   ├── search.py                 # 🔍 Semantic search & retrieval
│   │   ├── notifications.py          # 📨 Send messages (Slack/SMS/Email)
│   │   ├── calendar.py               # 📅 Schedule management
│   │   └── memory.py                 # 🧠 Context & conversation memory
│   │
│   ├── 🌊 workflows/                 # THE FLOWS - Multi-step processes
│   │   ├── __init__.py               # Workflow registry
│   │   ├── slack_intake.py           # Slack → Classify → Store → Notify
│   │   ├── sms_intake.py             # SMS → Classify → Store → Notify
│   │   ├── task_routing.py           # Task → Analyze → Assign → Track
│   │   └── listing_flow.py           # Listing → Validate → Create → Notify
│   │
│   ├── 📊 state/                     # THE MEMORY - Shared state schemas
│   │   ├── __init__.py
│   │   ├── message_state.py          # Message processing state
│   │   ├── agent_state.py            # Agent communication state
│   │   └── workflow_state.py         # Workflow execution state
│   │
│   ├── 🔌 webhooks/                  # THE LISTENERS - External entry points
│   │   ├── __init__.py
│   │   ├── slack.py                  # Slack Events API handler
│   │   ├── sms.py                    # Twilio webhook handler
│   │   └── supabase.py               # Database trigger handler
│   │
│   ├── 👷 workers/                   # THE WORKERS - Background processors
│   │   ├── __init__.py
│   │   ├── queue_processor.py        # Process message queues
│   │   ├── scheduler.py              # Scheduled tasks
│   │   └── monitor.py                # Health & performance monitoring
│   │
│   ├── 🔧 utils/                     # THE UTILITIES - Shared helpers
│   │   ├── __init__.py
│   │   ├── prompts.py                # Prompt templates
│   │   ├── validators.py             # Input validation
│   │   ├── formatters.py             # Output formatting
│   │   └── auth.py                   # Authentication/verification
│   │
│   ├── 💾 database/                  # THE CONNECTION - Minimal DB layer
│   │   ├── __init__.py
│   │   └── client.py                 # Supabase client (agents write here)
│   │
│   ├── 📝 schemas/                   # THE CONTRACTS - Data models
│   │   ├── __init__.py
│   │   ├── classification.py         # Classification schemas
│   │   ├── entities.py               # Business entities
│   │   └── responses.py              # API response models
│   │
│   ├── ⚙️ config/                    # THE SETTINGS
│   │   ├── __init__.py
│   │   ├── settings.py               # Environment config
│   │   └── constants.py              # System constants
│   │
│   ├── main.py                       # 🚪 THE ENTRY - 5 endpoints only
│   ├── langgraph.json                # 📋 THE MANIFEST - LangGraph config
│   └── .env                          # 🔐 THE SECRETS
│
├── 📱 apps/operations-center/         # THE EXPERIENCE (SwiftUI)
│   ├── OperationsKit/                # Shared framework
│   ├── iOS/                          # iPhone experience
│   ├── macOS/                        # Mac experience
│   └── Shared/                       # Common views
│
├── 🗄️ supabase/                      # THE DATA
│   └── migrations/                   # Database evolution
│
├── 🗑️ trash/                         # THE ARCHIVE
│   └── [old implementations]         # Historical reference
│
└── 📚 docs/                          # THE KNOWLEDGE
    └── [documentation]               # How it all works

```

## Key Design Principles

### 1. Visual Hierarchy
- **Icons** immediately convey purpose
- **Directory names** are self-explanatory
- **File names** describe function, not implementation

### 2. Clear Separation of Concerns
```
Agents    → The decision makers (WHO decides)
Tools     → The capabilities (WHAT they can do)
Workflows → The processes (HOW things flow)
State     → The memory (WHAT to remember)
Webhooks  → The listeners (WHERE input arrives)
Workers   → The processors (WHEN to act)
```

### 3. The 5-Endpoint Philosophy
```python
# main.py - The entire API surface
POST /webhooks/slack     # Slack messages arrive
POST /webhooks/sms       # SMS messages arrive
POST /classify           # Stream classification
POST /chat              # Agent conversation
GET  /status            # System health
```

### 4. Agent Registry Pattern
```python
# agents/__init__.py
AGENT_REGISTRY = {
    "orchestrator": OrchestratorAgent,
    "classifier": ClassifierAgent,
    "realtor": RealtorAgent,
    "listing": ListingAgent,
    "task": TaskAgent,
    "notification": NotificationAgent,
}

def get_agent(name: str) -> BaseAgent:
    """Get agent by name"""
    return AGENT_REGISTRY[name]()
```

### 5. Tool Composition
```python
# Tools are composable building blocks
from tools import database, search, notifications

class RealtorAgent:
    tools = [
        database.create_realtor,
        database.update_realtor,
        search.find_realtor,
        notifications.notify_realtor,
    ]
```

### 6. Workflow as Code
```python
# workflows/slack_intake.py
@workflow
async def process_slack_message(message: SlackMessage):
    """The complete Slack processing pipeline"""

    # Step 1: Classify
    classification = await classifier.classify(message)

    # Step 2: Store
    await database.store_classification(classification)

    # Step 3: Route to specialist
    specialist = orchestrator.route(classification)
    result = await specialist.process(classification)

    # Step 4: Notify
    await notifications.send_response(result)

    return result
```

## Migration Path

### Phase 1: Create Structure (Today)
```bash
# Create the new directory structure
mkdir -p apps/backend/api/{agents,tools,workflows,state,webhooks,workers,utils,schemas,config}
touch apps/backend/api/langgraph.json
```

### Phase 2: Move & Refactor (Tomorrow)
1. Move `classifier.py` → `agents/classifier.py`
2. Extract tools from existing code → `tools/`
3. Create workflows from existing logic → `workflows/`
4. Consolidate state definitions → `state/`

### Phase 3: Delete Redundancy (Day 3)
1. Delete all CRUD routers
2. Delete redundant database files
3. Archive old implementations

### Phase 4: Connect Everything (Day 4)
1. Wire up webhooks
2. Configure LangGraph
3. Test end-to-end flow

## The Result

When someone opens this project, they immediately see:
- **Where the intelligence lives** (agents/)
- **What capabilities exist** (tools/)
- **How things flow** (workflows/)
- **Where data goes** (database/)
- **How to extend it** (clear patterns)

No confusion. No searching. No documentation needed.

**"Simplicity is the ultimate sophistication."**

## File Size Targets

```
Before: 5,763 lines across 38 files
After:  1,500 lines across 25 files

Key Files:
- main.py:           50 lines  (5 endpoints)
- orchestrator.py:   150 lines (routing logic)
- classifier.py:     245 lines (existing, perfect)
- workflows/:        300 lines (4 workflows)
- tools/:            200 lines (reusable functions)
- agents/:           400 lines (5 specialist agents)
- webhooks/:         150 lines (3 entry points)
```

## The Philosophy

This isn't just a file structure. It's a statement:
- **We value clarity over cleverness**
- **We value purpose over patterns**
- **We value simplicity over features**

Every file earns its place. Every directory tells its story.

**This is how we build the future - one perfect component at a time.**