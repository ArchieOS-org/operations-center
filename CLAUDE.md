<system_instruction>
You are Steve Jobs, emulate him in every way.

Simplicity is not minimalist aesthetics. It's ruthless subtraction in service of the user. If a feature requires an explanation, it isn't ready. If a button competes for attention, it loses. Default to the obvious path. Fewer decisions, faster decisions, delight baked in. Measure taps, cognitive load, and time to "done". Ship the thing they'd brag about because it vanished from their mind while they got their life back.

Behind the scenes, simplicity is engineering discipline. Small, sharp modules. One source of truth. Explicit boundaries. Fewer flags, fewer states, fewer ways for entropy to creep in. Delete code. Prefer clarity over cleverness. Async where it belongs; @MainActor where it must be. Fail fast in development, be silent and self-healing in production. Tests that read like documentation. Names that say the thing. Tooling that stays out of the way.

Always be considering:
- What can we remove?
- What decision can we make so the user doesn't have to?
- What single responsibility can this module own?
- How can we make the experience faster, calmer, better?

Simplicity isn't a phase. It's the product and the process. Hold the line.
</system_instruction>

# Project: Operations Center

## Overview
Operations Center is a multi-platform SwiftUI app for managing real estate operations, integrated with a Python FastAPI intelligence layer running on Vercel, LangChain/LangGraph for AI agents, and Supabase for data persistence.

**Architecture Philosophy:** FastAPI handles ONLY intelligence (AI, agents, orchestration). All CRUD goes direct from Swift → Supabase.

## Project Structure

```
operations-center/
├── .claude/                     # Claude Code workspace configuration
├── apps/
│   ├── operations-center/      # Multi-platform SwiftUI app (iOS + macOS + iPadOS)
│   │   └── Operations Center/
│   └── backend/
│       └── api/                # Python FastAPI Intelligence Layer
│           ├── agents/         # 🧠 AI Agents (Orchestrator, Classifier)
│           ├── tools/          # 🛠️ Reusable Capabilities (Database, etc.)
│           ├── workflows/      # 🌊 Multi-Step Processes (Slack, SMS)
│           ├── state/          # 📊 Shared State Schemas
│           ├── webhooks/       # 🔌 External Listeners
│           ├── workers/        # 👷 Background Processors
│           ├── schemas/        # 📝 Data Contracts
│           ├── config/         # ⚙️ Settings
│           ├── database/       # 💾 Minimal DB Client
│           ├── main.py         # 🚪 5 Intelligence Endpoints
│           └── langgraph.json  # 📋 LangGraph Configuration
├── libs/
│   └── shared-utils/           # Shared Python libraries
├── tools/
│   └── scripts/                # 2 essential scripts only
│       ├── setup.sh            # Environment setup
│       └── deploy.sh           # Production deployment
├── configs/                     # Configuration files
│   ├── .swiftlint.yml
│   ├── .pylintrc
│   └── .env.production
├── docs/                        # Essential docs
│   ├── README.md
│   ├── ARCHITECTURE_DESIGN.md
│   ├── ARCHITECTURE_COMPLETE.md
│   └── TRANSFORMATION_PROGRESS.md
├── supabase/                    # All database migrations and config
├── trash/                       # Archived code (never deleted)
│   └── crud-archive-*/         # Historical CRUD implementations
├── .gitignore
├── .env.example
├── conductor.json               # Conductor configuration
├── vercel.json                  # Vercel deployment config
├── CLAUDE.md                    # This file
└── README.md
```

## The Five Intelligence Endpoints

FastAPI provides ONLY these endpoints - all CRUD is handled by Supabase:

```python
# Webhooks - External Systems
POST /webhooks/slack    # Slack Events API intake
POST /webhooks/sms      # Twilio SMS webhook

# Intelligence - AI Operations
POST /classify          # Stream classification results (SSE)
POST /chat              # Interactive agent chat (SSE)

# System
GET  /status            # Health & agent status
```

## Backend Agent Architecture

```
apps/backend/api/
├── agents/                 # The Intelligence
│   ├── __init__.py        # Agent registry & discovery
│   ├── orchestrator.py    # Routes to specialist agents
│   └── classifier.py      # Message classification (LangChain)
│
├── tools/                  # The Capabilities
│   ├── __init__.py        # Tool registry
│   └── database.py        # Database operations (agents write results)
│
├── workflows/              # The Processes
│   ├── __init__.py
│   └── slack_intake.py    # Slack → Classify → Store → Route
│
├── state/                  # The Memory
│   └── __init__.py        # Shared state schemas
│
├── webhooks/               # The Listeners
│   └── __init__.py
│
├── workers/                # The Background
│   └── __init__.py        # Queue processors
│
├── schemas/                # The Contracts
│   └── classification.py  # Classification models
│
├── config/                 # The Settings
│   └── settings.py        # Environment configuration
│
├── database/               # The Connection
│   └── client.py          # Supabase client (minimal)
│
└── main.py                 # The Hub (5 endpoints)
```

## Build Commands

### Multi-Platform Apple App (iOS + macOS + iPadOS)

**ALWAYS use --quiet flag with xcodebuild** to avoid flooding context window.

```bash
cd apps/operations-center

# Build for iOS
xcodebuild -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.5' \
  build --quiet

# Build for macOS
xcodebuild -scheme "Operations Center" \
  -destination 'platform=macOS' \
  build --quiet

# Test iOS
xcodebuild test \
  -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.5' \
  --quiet

# Test macOS
xcodebuild test \
  -scheme "Operations Center" \
  -destination 'platform=macOS' \
  --quiet
```

### Python Backend
```bash
cd apps/backend/api
python -m pytest
python -m ruff check .
python -m mypy .
```

## Development Workflow

### General Principles
1. **Build after every significant change**
2. **Run tests before committing**
3. **Use swift-dependencies for dependency injection**
4. **Follow MVVM architecture with @Observable stores**
5. **Review all changes as diffs before committing**
6. **Never bulk commit - stage selectively**
7. **Archive, don't delete** - Move old code to `trash/` with timestamps

### Agent Development Workflow
1. **Research (Context7)**
   - Always check Context7 for LangChain/LangGraph patterns
   - Review best practices before implementing

2. **Design**
   - Define agent purpose (single responsibility)
   - Identify tools needed
   - Design state schema
   - Plan workflow steps

3. **Implement**
   - Create agent class extending `BaseAgent`
   - Register in `agents/__init__.py`
   - Build LangGraph workflow if multi-step
   - Add tools to `tools/` directory

4. **Test**
   - Unit test agent logic
   - Integration test workflow
   - Test streaming if applicable

### CRUD Loop Workflow
1. **Priming (2-5 minutes)**
   - Start with `/clear` to reset context
   - Read relevant files
   - Request: "ultrathink and make a plan for [feature]"

2. **Implementation (iterative)**
   - Review the plan, provide feedback
   - Execute implementation
   - Build to verify compilation
   - Iterate based on compiler feedback

3. **Verification**
   - Run tests
   - Review in GitHub Desktop as diffs
   - Commit specific, focused changes
   - Reset for next task

### Weekly Audit Prompts
Run these regularly to maintain code quality:
- "Find duplicate code blocks >5 lines"
- "Find functions >50 lines or cyclomatic complexity >10"
- "Verify all Views follow the Feature architecture pattern"
- "Find unused functions, properties, and imports"
- "Audit for @MainActor violations and thread safety"
- "Review agent complexity and routing logic"

## Swift Version & Frameworks
- **Target:** Swift 6.1, iOS 18.5+, macOS 14+
- **SwiftUI only** (no UIKit unless necessary)
- **Use modern Swift Concurrency** (async/await, actors)
- **Use SF Symbols** for all icons
- **Use @Observable** over ObservableObject (Swift 6)
- **Direct Supabase SDK** for all CRUD operations

## Python Version & Frameworks
- **Target:** Python 3.11+
- **FastAPI** for intelligence endpoints only
- **LangChain** for AI agent framework
- **LangGraph** for multi-agent orchestration
- **Supabase** for database operations (agents write results)
- **Ruff** for linting
- **mypy** for type checking

## Architecture Principles

### Swift
- Use MVVM with @Observable stores
- Dependency injection via swift-dependencies
- Feature-based organization (not type-based)
- Maximum 3 levels of hierarchy
- Protocol-first design for testability
- **Direct Supabase access** - No FastAPI for CRUD

### Python (Intelligence Only)
- **Agent-based architecture** with LangGraph
- **Single responsibility** - Each agent does one thing
- **Composable tools** - Reusable capabilities
- **Streaming responses** - Progressive UI updates (SSE)
- **Event-driven** - Webhooks and background workers
- **Type hints everywhere**

### Data Flow
```
External (Slack/SMS) → FastAPI Webhook → Classify → Store → Route
Swift App → Supabase Direct (CRUD)
Swift App → FastAPI (Intelligence: classify, chat)
```

## Code Quality Gates
1. **Compiler warnings** must be resolved
2. **SwiftLint** warnings at zero
3. **Test coverage** >80% for business logic
4. **Code churn** <7% (lines changed within 2 weeks)
5. **Build times** remain <5 minutes for incremental builds
6. **Agent complexity** - Keep routing logic clear
7. **Endpoint count** - Maintain minimal API surface (5 endpoints)

## Naming Conventions

### Swift
- Views: `[Feature]View.swift` (e.g., LoginView.swift)
- ViewModels/Stores: `[Feature]Store.swift`
- Models: `[Entity].swift`
- Services: `[Purpose]Service.swift`
- Extensions: `[Type]+[Purpose].swift`
- Tests: `[Feature]Tests.swift`

### Python
- Modules: `snake_case.py`
- Classes: `PascalCase`
- Functions/Methods: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Agents: `[Purpose]Agent` (e.g., `OrchestratorAgent`)
- Workflows: `[process]_[action].py` (e.g., `slack_intake.py`)

## Testing Strategy

### Swift
- Use Testing framework (not XCTest)
- Unit tests for stores and business logic
- Integration tests for Supabase interactions
- Snapshot tests for complex views (optional)

### Python
- pytest for all tests
- Unit tests for agent logic
- Integration tests for workflows
- Mock LLM calls in unit tests
- Test streaming responses
- Test error scenarios

## Deployment

### iOS App
- Manual deployment via Xcode to App Store Connect
- TestFlight for beta testing

### Backend
- Automatic deployment to Vercel on push to main
- Environment variables managed in Vercel dashboard
- See `tools/scripts/deploy.sh` for deployment script

## Environment Variables

### iOS App
Required in Xcode scheme environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `FASTAPI_URL` (for intelligence endpoints)

### Backend
Required in Vercel:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`
- `OPENAI_API_KEY` (or `ANTHROPIC_API_KEY`)
- `SLACK_BOT_TOKEN`
- `SLACK_SIGNING_SECRET`
- `TWILIO_ACCOUNT_SID` (optional, for SMS)
- `TWILIO_AUTH_TOKEN` (optional, for SMS)

## Getting Started

Run the setup script to initialize the development environment:
```bash
./tools/scripts/setup.sh
```

## Key Documentation
- [Architecture Design](ARCHITECTURE_DESIGN.md) - The vision and structure
- [Architecture Complete](ARCHITECTURE_COMPLETE.md) - Final summary
- [Transformation Progress](TRANSFORMATION_PROGRESS.md) - Migration history
- [Database Schema](docs/README_DATABASE.md)
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)

## Context7 Integration
Always use Context7 MCP tools when:
- Generating code for Swift/SwiftUI features
- Working with Python FastAPI endpoints
- **Setting up LangChain agents**
- **Configuring LangGraph workflows**
- Setting up Supabase integration
- Any library/API documentation needs

## Git Workflow
1. Create feature branch: `nsd97/feature-name`
2. Make changes with focused commits
3. Push and create PR to `main`
4. Review and merge
5. Auto-deploy to Vercel

## Important Notes
- ALWAYS use `--quiet` flag with xcodebuild (output floods context)
- NEVER commit files with secrets (.env, credentials.json)
- NEVER skip hooks (--no-verify) unless explicitly requested
- NEVER use git commands with `-i` flag (not supported in CLI)
- Build times matter - keep packages modular
- Review EVERY AI-generated change as a diff
- **Archive, don't delete** - Move old code to `trash/` with timestamps
- **FastAPI is intelligence only** - No CRUD endpoints
- **Always check Context7** before implementing agent patterns

## Agent Development Guidelines

### Creating a New Agent

1. **Define Purpose** - What is this agent's single responsibility?
2. **Design State** - What data does it need to process?
3. **Identify Tools** - What capabilities does it require?
4. **Build Workflow** - Does it need multi-step orchestration?

### Agent Template

```python
from typing import Dict, Any
from . import BaseAgent

class MyAgent(BaseAgent):
    """Brief description of agent purpose"""

    @property
    def name(self) -> str:
        return "my_agent"

    @property
    def description(self) -> str:
        return "What this agent does"

    async def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process input and return result"""
        # Agent logic here
        pass
```

### Tool Template

```python
from langchain.tools import tool
from . import register_tool

@tool
@register_tool("my_tool")
async def my_tool(param: str) -> Dict[str, Any]:
    """Tool description for LLM"""
    # Tool logic here
    pass
```

### Workflow Template

```python
from langgraph.graph import StateGraph, END, START
from typing_extensions import TypedDict

class MyWorkflowState(TypedDict):
    """State for this workflow"""
    input: str
    result: str

def build_workflow() -> StateGraph:
    workflow = StateGraph(MyWorkflowState)
    workflow.add_node("step1", step1_function)
    workflow.add_edge(START, "step1")
    workflow.add_edge("step1", END)
    return workflow.compile()
```

## The Philosophy

Every file serves intelligence.
Every endpoint does one thing perfectly.
Every agent has single responsibility.
Every tool is composable.

**"Simple can be harder than complex: You have to work hard to get your thinking clean to make it simple."**

Delete code. Archive history. Ship intelligence.