# Slack Message to Inbox Flow - ACTUAL IMPLEMENTATION

```mermaid
flowchart TD
    %% External trigger
    SlackAPI[Slack Events API POST] --> WebhookHandler

    %% Webhook Handler
    subgraph WebhookHandler["main.py::slack_webhook()"]
        WH1{payload.type?}
        WH2[Return challenge]
        WH3[Call process_slack_message]
        WH4[Return 200 OK immediately]
    end

    WH1 -->|url_verification| WH2
    WH1 -->|event_callback| WH3
    WH3 --> WH4

    %% Slack Intake Workflow
    WH3 --> ValidateNode

    subgraph SlackIntake["workflows/slack_intake.py"]
        ValidateNode["validate_slack_event()"]
        ValidateCheck{Is valid?}
        ClassifyNode["classify_message()<br/>→ agents/classifier.py<br/>→ MessageClassifier.classify()"]
        StoreNode["store_in_database()<br/>→ INSERT slack_messages"]
        CreateNode["create_entities_node()<br/>→ workflows/entity_creation.py"]
        RouteNode["route_to_agent()<br/>→ get_agent('orchestrator')"]
        ResponseNode["prepare_response()"]
        ErrorNode[Return error]
    end

    ValidateNode --> ValidateCheck
    ValidateCheck -->|Invalid| ErrorNode
    ValidateCheck -->|Valid| ClassifyNode
    ClassifyNode --> StoreNode
    StoreNode --> CreateNode
    CreateNode --> RouteNode
    RouteNode --> ResponseNode

    %% Entity Creation
    CreateNode --> EntityCreation

    subgraph EntityCreation["workflows/entity_creation.py::create_entities_from_classification()"]
        EC1{classification.message_type?}
        EC2["resolve_assignee_from_hint()<br/>→ Fuzzy match realtors"]
        EC3["Create listing<br/>INSERT INTO listings<br/>status='new'"]
        EC4["⚠️ BUG: Create stray_task<br/>status='NEEDS_INFO'<br/>DATABASE REJECTS"]
        EC5["⚠️ BUG: Create stray_task<br/>notes=[] field doesn't exist<br/>DATABASE REJECTS"]
        EC6["Update slack_messages<br/>processing_status='skipped'"]
        EC7["Update slack_messages<br/>created_listing_id"]
        EC8["Update slack_messages<br/>created_task_id"]
        EC9["Update slack_messages<br/>created_task_id"]
    end

    EC1 -->|IGNORE| EC6
    EC1 -->|GROUP| EC2
    EC2 --> EC3
    EC3 --> EC7
    EC1 -->|INFO_REQUEST| EC2
    EC2 --> EC4
    EC4 -.->|FAILS| EC9
    EC1 -->|STRAY| EC2
    EC2 --> EC5
    EC5 -.->|FAILS| EC8

    EC6 --> RouteNode
    EC7 --> RouteNode
    EC8 --> RouteNode
    EC9 --> RouteNode

    %% Agent Routing
    RouteNode --> Orchestrator

    subgraph Orchestrator["agents/orchestrator.py"]
        OR1["⚠️ BROKEN: OrchestratorAgent<br/>NOT REGISTERED in agents/__init__.py"]
        OR2["get_agent('orchestrator')<br/>Returns None"]
        OR3["Return placeholder:<br/>'Agent processing not yet available'"]
    end

    OR1 -.-> OR2
    OR2 --> OR3
    OR3 --> ResponseNode

    %% Response (goes nowhere)
    ResponseNode --> DeadEnd

    subgraph DeadEnd["⚠️ NO IMPLEMENTATION"]
        DE1["Response string generated<br/>NEVER SENT TO SLACK"]
        DE2["Background task commented out"]
    end

    DE1 -.-> DE2

    %% Frontend Display
    Frontend[User opens inbox] --> InboxStore

    subgraph InboxStore["Stores/InboxStore.swift::fetchTasks()"]
        IS1["repository.fetchStrayTasks()"]
        IS2["repository.fetchListingTasks()"]
        IS3["Combine results"]
    end

    InboxStore --> IS1
    InboxStore --> IS2
    IS1 --> IS3
    IS2 --> IS3

    subgraph Repository["Shared/Repositories/SupabaseTaskRepository.swift"]
        R1["fetchStrayTasks()<br/>SELECT * FROM stray_tasks<br/>ORDER BY priority, created_at"]
        R2["fetchListingTasks()<br/>SELECT listing_tasks.*, listings.*<br/>FROM listing_tasks JOIN listings<br/>ORDER BY priority, created_at"]
        R3["⚠️ NO SLACK MESSAGE CONTEXT<br/>Messages array always empty"]
    end

    IS1 --> R1
    IS2 --> R2
    R1 --> R3
    R2 --> R3
    R3 --> Display

    Display[Display in InboxView]

    %% Database connections (what actually works)
    subgraph Database["Supabase Tables"]
        DB1[(slack_messages)]
        DB2[(listings)]
        DB3[(stray_tasks)]
        DB4[(listing_tasks)]
    end

    StoreNode -.->|WRITES| DB1
    EC3 -.->|WRITES| DB2
    EC4 -.->|FAILS TO WRITE| DB3
    EC5 -.->|FAILS TO WRITE| DB3
    R1 -.->|READS| DB3
    R2 -.->|READS| DB4

    %% Styling
    classDef broken fill:#ffcccc,stroke:#ff0000,stroke-width:2px
    classDef working fill:#ccffcc,stroke:#00ff00,stroke-width:2px
    classDef partial fill:#ffffcc,stroke:#ffaa00,stroke-width:2px

    class EC4,EC5,OR1,OR2,DE1,DE2,R3 broken
    class ValidateNode,ClassifyNode,StoreNode,R1,R2 working
    class EC3,EC7 partial
```

## Key Files and Functions

### Backend (Python FastAPI)

**Entry Point:**
- `app/main.py::slack_webhook()` (lines 122-161)
  - Handles URL verification
  - Calls `process_slack_message()`
  - Returns 200 OK immediately

**Workflow Orchestration:**
- `app/workflows/slack_intake.py::build_slack_intake_workflow()`
  - `validate_slack_event()` - Filters bots, checks required fields
  - `classify_message()` - Calls MessageClassifier agent
  - `store_in_database()` - Inserts into slack_messages table
  - `create_entities_node()` - Creates listings/tasks
  - `route_to_agent()` - Attempts orchestrator routing (broken)
  - `prepare_response()` - Generates response string (never sent)

**Classification:**
- `app/agents/classifier.py::MessageClassifier.classify()`
  - Uses OpenAI GPT-4o-mini
  - Returns ClassificationV1 schema
  - Determines message_type: IGNORE, GROUP, STRAY, INFO_REQUEST

**Entity Creation:**
- `app/workflows/entity_creation.py::create_entities_from_classification()`
  - `resolve_assignee_from_hint()` - Fuzzy matches realtor names
  - Creates listings for GROUP messages
  - **BUG:** Creates stray_tasks with invalid status "NEEDS_INFO"
  - **BUG:** References non-existent `notes` column

**Agent Registry:**
- `app/agents/__init__.py::AGENT_REGISTRY`
  - MessageClassifier: ✓ Registered
  - OrchestratorAgent: ✗ Commented out (not registered)

### Frontend (Swift/SwiftUI)

**Inbox Display:**
- `apps/Operations Center/Stores/InboxStore.swift::fetchTasks()`
  - Calls `repository.fetchStrayTasks()`
  - Calls `repository.fetchListingTasks()`
  - Combines and sorts results

**Data Repository:**
- `apps/Operations Center/Shared/Repositories/SupabaseTaskRepository.swift`
  - `fetchStrayTasks()` - Queries stray_tasks table
  - `fetchListingTasks()` - Queries listing_tasks + listings join
  - **MISSING:** No Slack message context included

### Database Schema

**Tables:**
- `slack_messages` - Stores all incoming Slack events with classification
- `listings` - Real estate listings (created from GROUP messages)
- `stray_tasks` - Standalone tasks (created from STRAY/INFO_REQUEST)
- `listing_tasks` - Tasks attached to listings

**Constraints:**
- `stray_tasks.status` CHECK constraint: `('OPEN', 'CLAIMED', 'IN_PROGRESS', 'DONE', 'FAILED', 'CANCELLED')`
  - **PROBLEM:** Code tries to use "NEEDS_INFO" (not allowed)
- `stray_tasks` has NO `notes` column
  - **PROBLEM:** entity_creation.py:208 references it

## Actual Success Rates

- **IGNORE messages:** ✓ 100% success (marked skipped)
- **GROUP messages:** ⚠️ Unknown (depends on listings.status constraint)
- **STRAY messages:** ✗ 0% success (notes column doesn't exist)
- **INFO_REQUEST messages:** ✗ 0% success (invalid status value)

## Critical Bugs

1. **entity_creation.py:196** - `status = "NEEDS_INFO"` violates database constraint
2. **entity_creation.py:208** - References non-existent `stray_tasks.notes` column
3. **agents/__init__.py** - OrchestratorAgent commented out, never executes
4. **main.py** - Response strings generated but never sent to Slack
5. **SupabaseTaskRepository.swift** - No connection to source Slack messages

## What Actually Works

✓ Webhook receives Slack events
✓ Classification via OpenAI
✓ Stores slack_messages records
✓ Frontend displays tasks (if they survive creation)

## What's Broken

✗ Entity creation for STRAY and INFO_REQUEST
✗ Agent orchestration (not registered)
✗ Slack responses (never sent)
✗ Slack message context in frontend

---

**Last Updated:** 2025-01-12
**Status:** PRODUCTION BROKEN - Multiple critical failures
