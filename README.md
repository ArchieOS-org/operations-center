# Operations Center

A production-quality multi-platform SwiftUI app for managing real estate operations, powered by Python FastAPI intelligence layer, LangChain/LangGraph AI agents, and Supabase database.

## Overview

Operations Center is a monorepo containing:
- **Multi-Platform Apple App**: SwiftUI native app for iOS, iPadOS, and macOS following Things 3 UX patterns
- **Python Intelligence Layer**: FastAPI serverless functions for AI classification and multi-agent orchestration
- **Shared Libraries**: Reusable Swift packages and Python utilities
- **Infrastructure**: Supabase for data persistence, Vercel for serverless deployment

**Architecture Philosophy:** FastAPI handles ONLY intelligence (AI agents, classification, orchestration). All CRUD goes direct from Swift → Supabase.

## Project Structure

```
operations-center/
├── .claude/                     # Claude Code workspace configuration
├── apps/
│   ├── operations-center/      # Multi-platform SwiftUI app (iOS + iPadOS + macOS)
│   └── backend/
│       └── api/                # Python FastAPI Intelligence Layer
│           ├── agents/         # 🧠 AI Agents (Orchestrator, Classifier)
│           ├── tools/          # 🛠️ Reusable Capabilities
│           ├── workflows/      # 🌊 Multi-Step Processes
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
├── docs/                        # Essential documentation
│   ├── README.md
│   ├── ARCHITECTURE_DESIGN.md
│   ├── ARCHITECTURE_COMPLETE.md
│   └── TRANSFORMATION_PROGRESS.md
├── supabase/                    # All database migrations and config
├── trash/                       # Archived code (never deleted)
│   └── crud-archive-*/         # Historical implementations
├── .gitignore
├── .env.example
├── conductor.json               # Conductor configuration
├── vercel.json                  # Vercel deployment config
├── CLAUDE.md                    # AI development workflow guide
└── README.md                    # This file
```

## Quick Start

### Prerequisites

- **Apple Platforms Development**:
  - Xcode 15.5+ (with Swift 6.1)
  - iOS 18.5+ / iPadOS 18.5+ / macOS 14+ targets

- **Backend Development**:
  - Python 3.11+
  - pip or uv package manager

- **Database**:
  - Supabase account
  - Supabase CLI (optional, for local development)

### Setup

Run the automated setup script:

```bash
./tools/scripts/setup.sh
```

This script will:
1. Create Python virtual environment
2. Install Python dependencies
3. Resolve Swift Package Manager dependencies
4. Create `.env` file from template
5. Set up git hooks for code quality

### Manual Setup

If you prefer manual setup:

#### Backend
```bash
cd apps/backend/api
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -e ../../../libs/shared-utils
```

#### Multi-Platform Apple App
```bash
cd apps/operations-center
open "Operations Center.xcodeproj"
# Xcode will automatically resolve Swift Package dependencies
```

## Development

### Backend Development

```bash
cd apps/backend/api
source venv/bin/activate

# Run development server
uvicorn main:app --reload

# Run tests
pytest

# Lint code
ruff check .

# Type checking
mypy .
```

### Multi-Platform Apple App Development

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
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  --quiet

# Test macOS
xcodebuild test \
  -scheme "Operations Center" \
  -destination 'platform=macOS' \
  --quiet

# Lint (all platforms)
swiftlint lint --config ../../configs/.swiftlint.yml
```

## Architecture

### The Five Intelligence Endpoints

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

### Multi-Platform Apple App

Built using modern SwiftUI patterns for **iOS, iPadOS, and macOS**:
- **MVVM with @Observable stores** (Swift 6)
- **Dependency injection** via swift-dependencies
- **Feature-based organization** for scalability
- **Progressive disclosure** UX inspired by Things 3
- **Adaptive UI** that automatically adjusts to each platform
- **Maximum code sharing** with platform-specific optimizations where needed
- **Direct Supabase SDK** for all CRUD operations

Key patterns:
- Navigation via optional child stores
- Real-time updates via Supabase subscriptions
- Calm technology principles for ambient awareness

### Backend Intelligence Layer

FastAPI agent-based architecture (v3.0):
- **LangChain agents** for AI decision-making
- **LangGraph workflows** for multi-step orchestration
- **Streaming responses** for progressive UI updates (SSE)
- **Event-driven** webhooks and background workers
- **Minimal database layer** (agents write results to Supabase)

**Agent Architecture:**
```
apps/backend/api/
├── agents/          # The Intelligence
│   ├── orchestrator.py    # Routes to specialist agents
│   └── classifier.py      # Message classification
├── tools/           # Reusable Capabilities
│   └── database.py        # Database operations
├── workflows/       # Multi-Step Processes
│   └── slack_intake.py    # Slack → Classify → Store → Route
└── main.py          # 5 endpoints only
```

### Database

Supabase PostgreSQL with:
- 9 core tables for operations management
- Row-level security (RLS) policies
- Real-time subscriptions
- Automatic timestamps and soft deletes

## Key Features

### Year 1 (Operations Focus)
- [ ] Operations list with real-time updates
- [ ] Task assignment and tracking
- [ ] Realtor and listing management
- [x] Slack message integration with AI classification
- [x] Multi-agent system with LangGraph orchestration

### Year 2 (Chat Features)
- [ ] AI-powered chat interface
- [ ] Streaming LLM responses
- [ ] Context-aware suggestions
- [ ] Multi-modal interactions

## Testing

### Swift Tests (All Platforms)
```bash
cd apps/operations-center

# Test on iOS
xcodebuild test -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Test on macOS
xcodebuild test -scheme "Operations Center" \
  -destination 'platform=macOS'

# Test on iPad
xcodebuild test -scheme "Operations Center" \
  -destination 'platform=iPad Simulator,name=iPad Pro (12.9-inch) (6th generation)'
```

### Python Tests
```bash
cd apps/backend/api
source venv/bin/activate
pytest tests/ -v

# Test agents
pytest tests/agents/ -v

# Test workflows
pytest tests/workflows/ -v
```

## Deployment

### Backend (Vercel)
```bash
# Automatic deployment on push to main
git push origin main

# Manual deployment
./tools/scripts/deploy.sh
```

### Multi-Platform Apple App (App Store)

**iOS + iPadOS:**
1. Archive for iOS in Xcode
2. Upload to App Store Connect
3. Submit for review

**macOS:**
1. Archive for macOS in Xcode
2. Notarize with Apple
3. Upload to App Store Connect or distribute directly

See [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) for details.

## Environment Variables

Create `.env` file in the root directory:

```bash
# Supabase
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key

# OpenAI (or Anthropic)
OPENAI_API_KEY=your_openai_api_key
# ANTHROPIC_API_KEY=your_anthropic_api_key

# Slack
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_SIGNING_SECRET=your_signing_secret

# Twilio (Optional, for SMS)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
```

## Documentation

- [CLAUDE.md](CLAUDE.md) - AI-assisted development workflow
- [Architecture Design](ARCHITECTURE_DESIGN.md) - Vision and structure
- [Architecture Complete](ARCHITECTURE_COMPLETE.md) - Implementation summary
- [Transformation Progress](TRANSFORMATION_PROGRESS.md) - Migration history
- [Database Schema](docs/README_DATABASE.md) - Database structure
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Production deployment

## Development Workflow

### Using Claude Code

This project is optimized for AI-assisted development with Claude Code:

1. **Start with `/clear`** to reset context
2. **Read relevant files** before making changes
3. **Request "ultrathink and make a plan"** for complex features
4. **Review all changes as diffs** in GitHub Desktop
5. **Commit selectively** - never bulk commit
6. **Check Context7** before implementing agent patterns

See [CLAUDE.md](CLAUDE.md) for complete workflow guidelines.

### Agent Development

1. **Research** - Check Context7 for LangChain/LangGraph patterns
2. **Design** - Define purpose, state, tools, workflow
3. **Implement** - Create agent, register, build workflow
4. **Test** - Unit tests, integration tests, streaming

See [Agent Development Guidelines](CLAUDE.md#agent-development-guidelines) for templates.

### Code Quality

- **SwiftLint** enforces Swift style and best practices
- **Ruff** for Python linting and formatting
- **mypy** for Python type checking
- **Pre-commit hooks** run checks automatically
- **Test coverage** target: >80% for business logic
- **Endpoint count** maintained at 5 (intelligence only)

### Git Workflow

```bash
# Create feature branch
git checkout -b nsd97/feature-name

# Make changes, commit frequently
git add specific-files
git commit -m "Clear, descriptive message

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push and create PR
git push -u origin nsd97/feature-name
gh pr create --web
```

## Tech Stack

### Multi-Platform Apple (iOS + iPadOS + macOS)
- Swift 6.1
- SwiftUI (iOS 18.5+, iPadOS 18.5+, macOS 14+)
- Swift Package Manager
- Supabase Swift SDK
- swift-dependencies

### Backend Intelligence Layer
- Python 3.11+
- FastAPI (v3.0 - intelligence only)
- LangChain (AI agent framework)
- LangGraph (multi-agent orchestration)
- Supabase Python SDK (minimal usage)
- uvicorn (ASGI server)

### Infrastructure
- Supabase (PostgreSQL + Auth + Realtime)
- Vercel (Serverless deployment)
- GitHub Actions (CI/CD)

## Contributing

1. Read [CLAUDE.md](CLAUDE.md) for development guidelines
2. Follow the established architecture patterns
3. Write tests for new features
4. Keep code quality metrics high
5. Review all AI-generated code as diffs
6. **Archive, don't delete** - Move old code to `trash/`

## Performance Targets

- **App build time**: <5 minutes (incremental, any platform)
- **Backend response time**: <200ms (p95)
- **Streaming first token**: <500ms (p95)
- **Test coverage**: >80% business logic
- **Code churn**: <7% (2-week window)
- **SwiftLint warnings**: 0
- **Endpoint count**: 5 (maintained)

## Maintenance

### Weekly Audits

Run these prompts with Claude Code:
- "Find duplicate code blocks >5 lines"
- "Find functions >50 lines or cyclomatic complexity >10"
- "Find unused functions, properties, and imports"
- "Audit for @MainActor violations and thread safety"
- "Review agent complexity and routing logic"

### Dependency Updates

```bash
# Swift packages
cd apps/operations-center
xcodebuild -resolvePackageDependencies

# Python packages
cd apps/backend/api
pip list --outdated
pip install --upgrade package-name
```

## Architecture Evolution

This project underwent a significant architectural transformation (November 2025):

**Before (v2.0):**
- 5,763 lines of Python code
- 52+ CRUD endpoints in FastAPI
- Mixed intelligence and data access
- Redundant with Supabase capabilities

**After (v3.0):**
- 1,431 lines of focused intelligence code (-75%)
- 5 intelligence endpoints only (-90%)
- Clear separation: FastAPI = Intelligence, Supabase = CRUD
- Agent-based architecture with LangGraph

See [ARCHITECTURE_COMPLETE.md](ARCHITECTURE_COMPLETE.md) for details.

## License

[Your License Here]

## Support

For questions or issues:
- Check [docs/](docs/) directory for detailed documentation
- Review [CLAUDE.md](CLAUDE.md) for development patterns
- Open an issue on GitHub

## Acknowledgments

Built following modern best practices from:
- [Point-Free](https://www.pointfree.co/) - swift-dependencies, architecture patterns
- [Supabase](https://supabase.com/) - Backend infrastructure
- [Things 3](https://culturedcode.com/things/) - UX inspiration
- [LangChain](https://www.langchain.com/) - AI agent framework
- Production SwiftUI guide (2025) - Architecture methodology

---

**"Simplicity is the ultimate sophistication."** - Leonardo da Vinci

Made with Claude Code following production-quality patterns for maintainable AI-assisted development.