# Operations Center

> **Status**: 🚧 **65% Complete** - Core infrastructure working, intelligence layer partially implemented, integration gaps exist

A multi-platform SwiftUI app for managing real estate operations with Python FastAPI intelligence layer, LangChain/LangGraph AI agents, and Supabase database.

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green.svg)](https://fastapi.tiangolo.com)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2018.5%2B-blue.svg)](https://developer.apple.com/xcode/swiftui/)

## What Actually Works (December 2025)

### ✅ Production-Ready
- **Swift App CRUD**: Full-featured task/listing management via direct Supabase integration
- **Supabase Database**: 22 migrations, 9 tables, RLS policies (partial), real-time subscriptions
- **Slack Message Intake**: Webhook → Batch → Classify → Store → Create entities (end-to-end working)
- **LangChain Classifier**: OpenAI-powered message classification with structured output
- **Swift Architecture**: MVVM + @Observable + dependency injection + feature-based organization

### 🚧 Partially Working
- **Real-time Sync**: Only `activities` table subscribed (not `agent_tasks` - gap!)
- **FastAPI Endpoints**: 5 endpoints exist, 3 functional (Slack webhook, status, classify stub)
- **Swift App Features**: 70% screens working (Inbox, My Tasks, My Listings, Browse), 30% stubs (Settings, Logbook, Team views)
- **Backend Intelligence**: Classifier works, orchestrator exists but specialist agents are TODO scaffolding

### ❌ Broken / Incomplete
- **Integration Layer**: Swift app has **ZERO network clients** calling FastAPI - intelligence unreachable
- **Orchestrator Agent**: Not registered in agent registry, `/chat` endpoint fails
- **4 Specialist Agents**: Realtor, Listing, Task, Notification agents are TODO stubs (return "not implemented")
- **SMS Webhook**: Returns 501 "not implemented"
- **Streaming**: `/classify` and `/chat` endpoints claim SSE but return single JSON chunks
- **Background Workers**: All disabled (commented out in lifespan)
- **Authentication**: FastAPI has ZERO auth middleware (wide open)
- **Slack Verification**: Signature validation is TODO stub (security gap)
- **SettingsView**: Empty placeholder (no sign-out, no profile)
- **LogbookView**: Screen exists but fetch never wired
- **Test Coverage**: <5% (only batched classification tested)

---

## Quick Start

### Prerequisites

**Apple Development:**
- Xcode 15.5+ with Swift 6.1
- iOS 18.5+ / iPadOS 18.5+ / macOS 14+

**Backend:**
- Python 3.11+
- Supabase account + project
- OpenAI API key

### 1. Clone & Setup

```bash
# Clone repository
git clone https://github.com/your-org/operations-center.git
cd operations-center

# Run automated setup
./tools/scripts/setup.sh
```

This creates venv, installs dependencies, resolves SPM packages, creates `.env` from template.

### 2. Configure Environment

Copy `.env.example` to `.env` and fill in:

```bash
# Required
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_key
OPENAI_API_KEY=sk-proj-your-key

# Optional (for Slack integration)
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_SIGNING_SECRET=your_secret
```

### 3. Run Database Migrations

```bash
cd supabase
supabase db push
# Or manually apply migrations from supabase/migrations/
```

### 4. Start Backend (Optional - for Slack integration only)

```bash
cd apps/backend/api
source venv/bin/activate
uvicorn main:app --reload --port 8000
```

**Note**: Swift app works **without** backend (direct Supabase CRUD).

### 5. Build & Run Swift App

```bash
cd apps/operations-center
open "Operations Center.xcodeproj"
# Xcode: Select scheme "Operations Center" → iOS Simulator → Run
```

**Or via command line:**

```bash
# iOS
xcodebuild -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build -quiet

# macOS
xcodebuild -scheme "Operations Center" \
  -destination 'platform=macOS' \
  build -quiet
```

---

## Project Structure

```
operations-center/
├── apps/
│   ├── Operations Center/          # SwiftUI multi-platform app
│   │   ├── Operations Center/
│   │   │   ├── Features/          # 11 feature modules (70% complete)
│   │   │   ├── Components/        # App-level components
│   │   │   ├── Dependencies/      # Repository clients (Supabase)
│   │   │   ├── State/             # AppState (@Observable global)
│   │   │   └── Utilities/         # Helpers
│   │   ├── Packages/
│   │   │   └── OperationsCenterKit/  # Design system SPM package
│   │   └── Operations CenterTests/    # <5% coverage (CRITICAL)
│   │
│   └── backend/api/               # Python FastAPI intelligence
│       ├── agents/                # Classifier (works), Orchestrator (broken)
│       ├── workflows/             # Slack intake (works), SMS (stub)
│       ├── tools/                 # Database tools (defined, unused)
│       ├── queue/                 # Message batching (works)
│       └── main.py                # 5 endpoints (3 working)
│
├── supabase/
│   ├── migrations/                # 22 migrations (1,578 lines SQL)
│   └── seed/                      # Dev seed data
│
├── docs/                          # 74 markdown files
│   ├── README.md                  # Documentation index
│   ├── README_API.md              # Endpoint reference
│   ├── README_DATABASE.md         # Schema documentation
│   └── SWIFT_TESTING_GUIDE.md     # Testing framework guide
│
├── Audit_Reports/                 # 32 quality audit files
├── tools/scripts/                 # setup.sh, deploy.sh
└── configs/                       # .swiftlint.yml, .pylintrc
```

---

## Architecture

### Data Flow (Current Reality)

```
┌─────────────────────────────────────────────────────┐
│                  EXTERNAL WORLD                      │
│         Slack Messages    |    Swift App Users       │
└───────────┬───────────────┼───────────┬──────────────┘
            │               │           │
            ▼               │           ▼
     ┌──────────────┐       │    ┌──────────────┐
     │   FastAPI    │       │    │  Swift App   │
     │  (Vercel)    │       │    │ iOS/macOS    │
     │              │       │    └──────┬───────┘
     │ 5 Endpoints  │       │           │
     │ - Slack ✅   │       │           │ CRUD (100%)
     │ - Classify🚧 │       │           │
     │ - Chat ❌    │       │           ▼
     │ - Status ✅  │       │    ┌──────────────┐
     │ - SMS ❌     │       │    │   SUPABASE   │
     └──────┬───────┘       │    │              │
            │               │    │ - Database   │
            │ (writes only) │    │ - Auth       │
            │               │    │ - Realtime   │
            └───────────────┴────┤ - Storage    │
                                 └──────────────┘

                     ❌ MISSING: Swift → FastAPI clients
```

**Critical Gap**: Swift app has **no network layer** for FastAPI. Intelligence features exist but unreachable.

### The 5 Intelligence Endpoints

| Endpoint | Method | Status | Implementation | Swift Client |
|----------|--------|--------|----------------|--------------|
| `/webhooks/slack` | POST | ✅ WORKING | Full pipeline: batch → classify → store → create entities | N/A (external) |
| `/webhooks/sms` | POST | ❌ STUB | Returns 501 "not implemented" | N/A (external) |
| `/classify` | POST | 🚧 PARTIAL | Classifier works but no streaming, unreachable | ❌ Missing |
| `/chat` | POST | ❌ BROKEN | Orchestrator not registered, always fails | ❌ Missing |
| `/status` | GET | ✅ WORKING | Returns static JSON | ❌ Missing |

### Backend Agent Architecture (65% Complete)

```
app/
├── agents/
│   ├── classifier.py       ✅ WORKING (LangChain + OpenAI structured output)
│   └── orchestrator.py     ❌ BROKEN (exists but not registered, specialist agents are TODO)
│
├── workflows/
│   ├── slack_intake.py     ✅ WORKING (Slack → Batch → Classify → Store → Create)
│   ├── entity_creation.py  ✅ WORKING (57 activity templates, listing creation)
│   └── batched_classification.py  ✅ WORKING (2s batch timeout, tested)
│
├── tools/
│   └── database.py         📋 DEFINED, UNUSED (tools exist but not wired to agents)
│
├── queue/
│   └── message_queue.py    ✅ WORKING (in-memory batching, 2s timeout)
│
└── main.py                 🚧 PARTIAL (5 endpoints declared, 3 functional)
```

### Swift App Architecture (70% Complete)

```
Operations Center/
├── Features/
│   ├── Inbox/              ✅ WORKING - Unacknowledged listings + unclaimed tasks
│   ├── MyTasks/            ✅ WORKING - User's claimed agent tasks
│   ├── MyListings/         ✅ WORKING - Listings with user's activities
│   ├── AllTasks/           ✅ WORKING - System-wide tasks
│   ├── AllListings/        ✅ WORKING - Browse all listings
│   ├── Agents/             ✅ WORKING - Browse realtors
│   ├── Auth/               ✅ WORKING - Email + Google OAuth
│   ├── ListingDetail/      🚧 IN PROGRESS - Activity display, note submission incomplete
│   ├── Logbook/            ❌ BROKEN - Screen exists, fetch not wired
│   ├── Settings/           ❌ NOT STARTED - Empty placeholder
│   └── Team Views/         ❌ NOT USED - No navigation routes
│
├── Dependencies/
│   ├── TaskRepositoryClient         ✅ COMPLETE (Supabase CRUD)
│   ├── ListingRepositoryClient      ✅ COMPLETE
│   ├── ListingNoteRepositoryClient  ✅ COMPLETE
│   ├── RealtorRepositoryClient      ✅ COMPLETE
│   └── AuthClient                   ✅ COMPLETE
│
├── State/
│   └── AppState.swift      ✅ WORKING (@Observable global, real-time sync)
│
└── Packages/OperationsCenterKit/
    └── DesignSystem/       ✅ MATURE (50+ components, consistent tokens)
```

### Database Schema (Supabase)

**9 Tables:**
- `staff` - Staff members
- `realtors` - Real estate agents
- `listings` - Properties
- `listing_acknowledgments` - Inbox claim tracking
- `activities` - Listing-related tasks
- `agent_tasks` - Standalone tasks
- `listing_notes` - Notes on listings
- `task_notes` - Notes on tasks
- `slack_messages` - Classification results

**22 Migrations** (1,578 lines SQL)
**RLS Policies**: ⚠️ Partially enforced
**Real-time**: ✅ Working (activities only, agent_tasks gap)

---

## Development

### Backend

```bash
cd apps/backend/api
source venv/bin/activate

# Run server
uvicorn main:app --reload --port 8000

# Tests (15% coverage)
pytest tests/ -v

# Lint
ruff check .

# Type check
mypy .
```

### Swift App

```bash
cd apps/operations-center

# Build iOS
xcodebuild -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build -quiet

# Build macOS
xcodebuild -scheme "Operations Center" \
  -destination 'platform=macOS' \
  build -quiet

# Test (<5% coverage - CRITICAL)
xcodebuild test \
  -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -quiet

# Lint
swiftlint lint --config ../../configs/.swiftlint.yml
```

---

## Critical Issues (Must Fix Before Production)

### 🔴 Tier 1: Breaks Production

1. **Integration Gap** - Swift app has no FastAPI clients (intelligence unreachable)
2. **Orchestrator Not Registered** - `/chat` endpoint calls non-existent agent
3. **No Authentication** - FastAPI endpoints are wide open (no JWT validation)
4. **Slack Verification Missing** - Signature check is TODO stub (security vulnerability)
5. **Classifier Blocking** - Uses synchronous `.invoke()` instead of `.ainvoke()` (blocks event loop)

### 🟡 Tier 2: Degrades UX

6. **No Real Streaming** - SSE endpoints return single chunks (false promise)
7. **Real-time Gap** - Only `activities` subscribed, not `agent_tasks`
8. **SettingsView Empty** - No sign-out, no user profile
9. **LogbookView Broken** - Screen exists but fetch not connected
10. **Test Coverage <5%** - Critical production risk

### 🟠 Tier 3: Incomplete Features

11. **SMS Webhook Stub** - Returns 501, no Twilio integration
12. **Background Workers Disabled** - All commented out in lifespan
13. **4 Specialist Agents Missing** - Orchestrator routes but agents return "not implemented"
14. **Tools Not Wired** - Database tools defined but no agent can call them

---

## What to Build Next

**Sprint 1: Close Integration Gap (2-3 days)**
1. Create `IntelligenceAPIClient` in Swift
2. Wire `/classify` endpoint (first-token streaming)
3. Implement basic auth middleware on FastAPI
4. Register OrchestratorAgent in agent registry

**Sprint 2: Fix Critical Features (3-5 days)**
5. Implement SettingsView (sign-out, profile)
6. Wire LogbookView fetch
7. Subscribe to `agent_tasks` in real-time
8. Fix classifier to use `.ainvoke()` (async)

**Sprint 3: Build Specialist Agents (5-7 days)**
9. Create RealtorAgent (queries realtor data, assigns tasks)
10. Create ListingAgent (updates listings, creates activities)
11. Create TaskAgent (task CRUD, note management)
12. Create NotificationAgent (Slack acknowledgments)

**Sprint 4: Testing & Security (3-5 days)**
13. Add test coverage to 30%+ (critical paths)
14. Implement Slack signature verification
15. Add RLS policy completion
16. Enable background workers with monitoring

---

## Tech Stack

**Frontend (iOS + iPadOS + macOS):**
- Swift 6.1
- SwiftUI (iOS 18.5+, iPadOS 18.5+, macOS 14+)
- SPM: supabase-swift (2.5.1+), swift-dependencies (1.0.0+)
- Architecture: MVVM + @Observable + DI

**Backend:**
- Python 3.11+
- FastAPI 0.115.13+
- LangChain 0.3.0+ (AI agents)
- LangGraph (multi-agent orchestration)
- Supabase Python SDK 2.10.0+
- OpenAI (LLM provider)

**Infrastructure:**
- Supabase (PostgreSQL + Auth + Realtime + Storage)
- Vercel (Serverless FastAPI deployment)
- GitHub Actions (CI/CD - not configured)

---

## Testing

**Current Status:**
- Python: ~15% coverage (batched classification only)
- Swift: <5% coverage (MyTasksStoreTests only)
- Integration: 0% coverage
- **Production Risk: CRITICAL**

**Target:**
- Business logic: >80%
- Repositories: >60%
- Workflows: >70%

---

## Deployment

### Backend (Vercel)

```bash
# Automatic on push to main
git push origin main

# Manual
./tools/scripts/deploy.sh
```

**Status:** ✅ Configured, ⚠️ Secrets in git (`.env.production` exposed - FIX!)

### Swift App (App Store)

**iOS + iPadOS:**
1. Archive for iOS in Xcode
2. Upload to App Store Connect
3. Submit for review

**macOS:**
1. Archive for macOS
2. Notarize with Apple
3. Distribute via App Store or directly

**Status:** ✅ Builds successfully, ❌ 30% features incomplete

---

## Documentation

**74 markdown files across:**
- [docs/](docs/) - Developer documentation (11 files)
- [Audit_Reports/](Audit_Reports/) - Quality audits (32 files)
- Root - Architecture, setup, deployment (14 files)

**Key Reads:**
- [CLAUDE.md](CLAUDE.md) - AI-assisted workflow guide
- [docs/README_API.md](docs/README_API.md) - Endpoint reference
- [docs/README_DATABASE.md](docs/README_DATABASE.md) - Schema documentation
- [docs/SWIFT_TESTING_GUIDE.md](docs/SWIFT_TESTING_GUIDE.md) - Testing patterns

---

## Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| App build time (incremental) | <5 min | ~3 min | ✅ |
| Backend response (p95) | <200ms | ~50ms | ✅ |
| Streaming first token (p95) | <500ms | N/A | ❌ Not implemented |
| Test coverage | >80% | <5% | ❌ CRITICAL |
| SwiftLint warnings | 0 | ~5 | 🚧 |
| Endpoint count | 5 | 5 | ✅ |

---

## Contributing

1. Read [CLAUDE.md](CLAUDE.md) for development workflow
2. Follow MVVM + @Observable patterns
3. Write tests (currently <5% - unacceptable)
4. Keep endpoints minimal (5 total)
5. Archive, don't delete (use `trash/` directory)
6. Review all changes as diffs before committing

---

## License

[Your License Here]

---

## Support

**Questions?**
- Check [docs/README.md](docs/README.md) for documentation index
- Review [CLAUDE.md](CLAUDE.md) for development patterns
- Open GitHub issue

**Known Issues:**
- See [Critical Issues](#critical-issues-must-fix-before-production) above
- Check [Audit_Reports/](Audit_Reports/) for detailed analysis

---

## Acknowledgments

Built following patterns from:
- [Point-Free](https://www.pointfree.co/) - swift-dependencies, architecture
- [Supabase](https://supabase.com/) - Backend infrastructure
- [Things 3](https://culturedcode.com/things/) - UX inspiration
- [LangChain](https://www.langchain.com/) - AI agent framework

---

**"Simplicity is the ultimate sophistication."** - Leonardo da Vinci

**Reality check**: This codebase is 65% complete with solid foundations but critical gaps. Build the integration layer, add tests, ship it.

Made with Claude Code.
