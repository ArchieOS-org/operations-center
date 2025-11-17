# DISPATCH: THE STRATEGIC BLUEPRINT

**This isn't a refactor. This is a transformation.**

---

## MISSION STATEMENT

Transform "Operations Center" from a bureaucratic label into **Dispatch** — a product with a singular purpose: route intelligence from where it emerges to where it belongs. Fast. Clean. Obvious.

---

## THE THREE PHASES

### PHASE 1: FOUNDATION (Backend + Database + API Contract)
*Duration: 1-2 weeks*
*Risk: Medium*

Database schema, API endpoints, and contracts established. Old and new systems run in parallel.

### PHASE 2: EXECUTION (Swift Refactor + Data Migration)
*Duration: 2-3 weeks*
*Risk: High (scale)*

Frontend rebuilt using new terminology. Database migrated with zero downtime.

### PHASE 3: CUT-OVER (The Instant Switch)
*Duration: Hours*
*Risk: Low (if Phases 1-2 executed correctly)*

Flip the switch. Old becomes deprecated. Dispatch becomes production.

---

## PHASE 1: FOUNDATION

### 1.1 DATABASE MIGRATION (Supabase)

**Strategy:** Expand-Contract with Views (Zero Downtime)

**What Gets Renamed:**
```
OLD                      → NEW
activities               → dispatch_activities
agent_tasks              → dispatch_agent_tasks
task_id                  → mission_id (column)
task_category            → mission_category (column)
task_status              → mission_status (column)
```

**Migration Steps:**

#### Step 1.1A: Expansion (10 minutes)
```sql
-- Create new dispatch_* tables with exact schema copy
CREATE TABLE dispatch_activities AS SELECT * FROM activities;
CREATE TABLE dispatch_agent_tasks AS SELECT * FROM agent_tasks;

-- Rebuild all indexes, constraints, RLS policies on new tables
-- (Full SQL in research output)

-- Verify data consistency
SELECT COUNT(*) FROM activities; -- Must match dispatch_activities
```

**Critical:** Use `lock_timeout = '5s'` on all FK creation to prevent queue buildup.

#### Step 1.1B: Switch (< 100ms downtime)
```sql
BEGIN TRANSACTION;
  ALTER TABLE activities RENAME TO activities_deprecated;
  ALTER TABLE dispatch_activities RENAME TO activities;
  -- (Same for agent_tasks)
COMMIT;

-- Verify RLS policies followed the rename
SELECT * FROM pg_policies WHERE tablename = 'activities';
```

#### Step 1.1C: Cleanup (30+ minutes after switch)
```sql
-- Monitor application health for 30 minutes
-- Then drop deprecated tables
DROP TABLE activities_deprecated CASCADE;
DROP TABLE agent_tasks_deprecated CASCADE;

VACUUM FULL; ANALYZE;
```

**Testing Strategy:**
- Local: `supabase migration up` in `.conductor/miami`
- Staging: Run full migration, test for 24 hours
- Production: Execute during quiet hours (3-4 AM)

**Rollback Plan:**
```sql
-- If issues arise during switch:
ALTER TABLE activities RENAME TO dispatch_activities;
ALTER TABLE activities_deprecated RENAME TO activities;
-- Instantly back to old schema
```

---

### 1.2 VERCEL API ENDPOINTS (FastAPI)

**Strategy:** Path-Prefix Versioning + Edge Config

**Current State:**
```
POST /webhooks/slack
POST /webhooks/sms
POST /classify
POST /chat
GET  /status
```

**Target State (Both Active Simultaneously):**
```
# OLD (operations)
POST /operations/webhooks/slack
POST /operations/webhooks/sms
POST /operations/classify
POST /operations/chat
GET  /operations/status

# NEW (dispatch)
POST /intake/slack
POST /intake/sms
POST /reason/classify
POST /reason/query
GET  /observe/health
POST /route/dispatch (new)
GET  /observe/agents (new)
GET  /observe/metrics (new)
```

**Implementation:**

#### File Structure:
```python
# apps/backend/api/main.py
from fastapi import FastAPI
from .routers import operations, dispatch

app = FastAPI()

# Mount both versions (ALWAYS both active)
app.include_router(operations.router, prefix="/operations")
app.include_router(dispatch.router)  # dispatch uses root-level namespaces

# Read Edge Config to determine which is "active" (for backward compat)
@app.middleware("http")
async def rewrite_legacy_paths(request, call_next):
    # If request is /classify, rewrite to /operations/classify or /dispatch/reason/classify
    # Based on Edge Config flag
    pass
```

#### Routers:
```python
# apps/backend/api/routers/operations.py
# (Existing endpoints, unchanged logic, just wrapped in prefix)

# apps/backend/api/routers/dispatch.py
# (New Dispatch endpoints with cleaner contracts)
```

**Deployment:**
1. Push branch with both routers to Vercel
2. Both endpoint sets active immediately
3. Edge Config still points to `/operations`
4. Test `/dispatch/*` endpoints in preview
5. When ready: Update Edge Config → instant switch

**Rollback:**
- Flip Edge Config back to `/operations` prefix
- Takes < 5 seconds globally
- No rebuild, no redeploy

---

### 1.3 NEW API CONTRACT DESIGN

**Grouped by Responsibility:**

#### **Intake** (Reception)
```
POST /intake/slack   → acknowledge Slack event, queue for processing
POST /intake/sms     → acknowledge SMS, queue for processing
```
Returns: `{ event_id, status: "queued", timestamp }`

**Why:** Webhook handlers return instantly. No bloat.

---

#### **Reason** (Cognition)
```
POST /reason/classify → stream classification results
POST /reason/query    → interactive reasoning (chat replacement)
```
Response: **Server-Sent Events** with structured event types
```
event: metadata
data: { "classification_id": "c-123" }

event: classification
data: { "message_type": "STRAY", "confidence": 0.92, ... }

event: complete
data: { "id": "c-123", "status": "success" }
```

**Why:** Machine-readable. Parser knows when stream ends.

---

#### **Route** (Orchestration)
```
POST /route/dispatch        → send classified signal to destinations
GET  /route/status/:id      → track dispatch progress
POST /route/replay/:id      → re-process event
```

Dispatch body supports **multi-destination routing:**
```json
{
  "classification_id": "c-789",
  "destinations": [
    { "type": "storage", "target": "supabase", "table": "messages" },
    { "type": "notification", "target": "slack", "channel_id": "..." },
    { "type": "agent", "target": "task_orchestrator" }
  ]
}
```

**Why:** Routing is explicit. Enables replay, auditing, multi-target dispatch.

---

#### **Observe** (Monitoring)
```
GET /observe/health   → liveness + readiness + queue depth
GET /observe/agents   → list available agents + capabilities
GET /observe/metrics  → operational metrics (latency, throughput, errors)
GET /observe/logs/:id → full trace for specific operation
```

**Why:** Separates operational monitoring from functional API.

---

### 1.4 PAYLOAD SIMPLIFICATION

**Before (Task):**
```json
{
  "task_id": "uuid",
  "task_category": "SHOWING_TASKS",
  "status": "open",
  "assigned_staff_id": "...",
  "due_date": "..."
}
```

**After (Mission):**
```json
{
  "mission_id": "uuid",
  "mission_type": "SHOWING",
  "status": "active",
  "assigned_to": "...",
  "due_at": "...",
  "confidence": 0.92,
  "routing_decision": {
    "auto_dispatch": true,
    "reason": "Above 0.7 threshold"
  }
}
```

**Key Changes:**
1. `mission` replaces `task` (semantic clarity)
2. Confidence included in payload (trust signal)
3. Routing decision explicit (not implicit)
4. Idempotency keys everywhere (client-safe retries)

---

## PHASE 2: EXECUTION

### 2.1 SWIFT CODEBASE REFACTOR

**Scope:**
- **108 "Task" type references** to rename
- **129 function/variable names** with "task"
- **3 feature folders** (`AllTasks`, `MyTasks`, `Tasks`)
- **15+ Swift files** directly referencing task types

**Strategy:** 8-Phase Incremental Refactor (8-14 hours)

#### Phase 2.1A: Preparation (30 min)
```bash
# Create feature branch
git checkout -b nsd97/rename-task-to-mission

# Baseline snapshot
rg "AgentTask|TaskStatus|TaskRepository" apps --type swift > /tmp/baseline.txt

# Clean build
xcodebuild -scheme "Operations Center" build -quiet
```

#### Phase 2.1B: Xcode Refactor — Types (1-2 hours)
Use Xcode's built-in refactor (Right-click → Rename):
```
AgentTask       → AgentMission
TaskStatus      → MissionStatus
TaskRepository  → MissionRepository
TaskCard        → MissionCard
AllTasksView    → AllMissionsView
MyTasksView     → MyMissionsView
```

**Build after each rename.** Compiler enforces completion.

Commit: `"Rename Types: Task → Mission"`

#### Phase 2.1C: File Renaming (1-2 hours)
Rename in Project Navigator (Xcode updates pbxproj automatically):
```
AgentTask.swift        → AgentMission.swift
TaskWithMessages.swift → MissionWithMessages.swift
TaskCard.swift         → MissionCard.swift
AllTasks/              → AllMissions/
MyTasks/               → MyMissions/
```

Commit after each file: `"Rename file: Old.swift → New.swift"`

#### Phase 2.1D: Code Identifiers (2-3 hours)
Function/variable renames:
```swift
loadTasks()     → loadMissions()
taskId          → missionId
taskCategory    → missionType
taskList        → missionList
```

Use Xcode refactor for public APIs, Find & Replace for local vars.

Build every 20 renames.

#### Phase 2.1E: CodingKeys (CRITICAL - 1 hour)
```swift
// BEFORE (maps to DB columns)
enum CodingKeys: String, CodingKey {
    case id = "task_id"
    case category = "task_category"
}

// AFTER (DB columns renamed in Phase 1)
enum CodingKeys: String, CodingKey {
    case id = "mission_id"
    case type = "mission_type"
}
```

**DO NOT change until database Phase 1 complete.**

Mark with comments:
```swift
case id = "mission_id"  // Maps to DB column - coordinated with backend
```

#### Phase 2.1F: String Literals & Comments (1-2 hours)
```swift
// File headers
//  Operations Center  →  //  Dispatch

// Route names (if client-controlled)
"/tasks"  →  "/missions"
```

**Skip enum raw values** (those are API contracts):
```swift
case open = "OPEN"  // Backend contract - do NOT change
```

#### Phase 2.1G: Tests (1-2 hours)
```
TaskRepositoryTests  → MissionRepositoryTests
TaskMockData         → MissionMockData
```

Run test suite:
```bash
xcodebuild test -scheme "Operations Center" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.5' -quiet
```

Must pass 100%.

#### Phase 2.1H: Verification (1 hour)
```bash
# Search for any missed "Task" references
rg "AgentTask|TaskStatus|TaskRepository" apps --type swift

# Should return 0 matches for old names

# Clean build from scratch
xcodebuild clean -quiet
xcodebuild build -quiet
```

**Checklist:**
- [ ] All types renamed
- [ ] All files renamed
- [ ] All function/var names updated
- [ ] CodingKeys match new DB schema
- [ ] Tests pass
- [ ] Project builds clean
- [ ] Schemes tracked in git

---

### 2.2 PYTHON BACKEND UPDATES

Update all table references in `apps/backend/api/`:

```python
# OLD
await db.from_("activities").select("*")
await db.from_("agent_tasks").select("*")

# NEW
await db.from_("dispatch_activities").select("*")
await db.from_("dispatch_agent_tasks").select("*")
```

**Files to update:**
- `tools/database.py` (Supabase queries)
- `workflows/slack_intake.py` (storage calls)
- All agent implementations that write results

**Testing:**
```bash
cd apps/backend/api
python -m pytest
```

---

## PHASE 3: CUT-OVER

### 3.1 PRE-FLIGHT CHECKLIST

Before flipping the switch:

**Database:**
- [ ] Staging migration successful (24+ hours stable)
- [ ] Production backup taken
- [ ] Rollback script tested
- [ ] RLS policies verified on new tables
- [ ] Foreign keys intact
- [ ] Row counts match (old vs. new tables)

**Backend:**
- [ ] Both `/operations` and `/dispatch` endpoints live
- [ ] Preview deployment tested
- [ ] Edge Config created with default to `/operations`
- [ ] Monitoring dashboards updated for new metrics
- [ ] Rollback procedure documented

**Frontend:**
- [ ] Swift codebase builds clean (iOS + macOS)
- [ ] All tests pass
- [ ] CodingKeys match new DB schema
- [ ] Xcode schemes tracked in git
- [ ] TestFlight build deployed

**Team:**
- [ ] On-call engineers notified
- [ ] Maintenance window scheduled (quiet hours)
- [ ] Communication plan for users (if user-facing)

---

### 3.2 THE SWITCH SEQUENCE

**Time: ~2 hours (with monitoring)**

#### Hour 0:00 — Database Switch
```sql
-- Execute Phase 1.1B (Switch migration)
BEGIN TRANSACTION;
  ALTER TABLE activities RENAME TO activities_deprecated;
  ALTER TABLE dispatch_activities RENAME TO activities;
  -- (repeat for agent_tasks)
COMMIT;

-- Verify (takes ~5 min)
SELECT COUNT(*) FROM activities;
SELECT * FROM pg_policies WHERE tablename = 'activities';
```

#### Hour 0:10 — Backend Deployment
```bash
# Deploy updated Python backend (with new table names)
git push origin main

# Vercel auto-deploys
# Both /operations and /dispatch active
# Edge Config still points to /operations
```

#### Hour 0:20 — Swift Deployment
```bash
# Deploy updated Swift app to TestFlight
# (Points to new mission_id, mission_type columns)

# Internal testing: 30 minutes
# Verify app reads/writes correctly
```

#### Hour 1:00 — Edge Config Flip
```bash
# Switch API traffic to Dispatch endpoints
curl -X PATCH https://api.vercel.com/v1/edge-config/YOUR_ID/items \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "items": [{
      "operation": "upsert",
      "key": "api_version",
      "value": "dispatch"
    }]
  }'

# Traffic now routes to /dispatch/* endpoints
# Old /operations/* endpoints still active (for rollback)
```

#### Hour 1:05 — Monitor
Watch for 30+ minutes:
- Error rates (should be < 0.001%)
- Query latency (should match baseline)
- Classification success rate
- Slack/SMS intake working
- No RLS violations in logs

#### Hour 1:35 — Cleanup (if stable)
```sql
-- Drop deprecated tables
DROP TABLE activities_deprecated CASCADE;
DROP TABLE agent_tasks_deprecated CASCADE;

VACUUM FULL; ANALYZE;
```

#### Hour 2:00 — Done
Dispatch is production. Operations Center is history.

---

### 3.3 ROLLBACK PROCEDURE

If issues detected during monitoring:

#### Instant Rollback (< 10 seconds)
```bash
# Revert Edge Config to /operations
curl -X PATCH https://api.vercel.com/v1/edge-config/YOUR_ID/items \
  -d '{ "items": [{ "operation": "upsert", "key": "api_version", "value": "operations" }] }'
```

API traffic routes back to `/operations/*` endpoints.

#### Database Rollback (if schema issues)
```sql
BEGIN TRANSACTION;
  ALTER TABLE activities RENAME TO dispatch_activities;
  ALTER TABLE activities_deprecated RENAME TO activities;
COMMIT;
```

App reads from old schema. Investigate root cause.

---

## COMPREHENSIVE FILE MANIFEST

Every file, every table, every endpoint that changes.

### Database (Supabase)
```
TABLES RENAMED:
├─ activities               → dispatch_activities
├─ agent_tasks              → dispatch_agent_tasks

COLUMNS RENAMED:
├─ task_id                  → mission_id
├─ task_category            → mission_type
├─ task_status              → mission_status

RLS POLICIES RECREATED:
├─ "Public can read listing tasks"  → "Public can read dispatch missions"
├─ "Public can read stray tasks"    → "Public can read dispatch missions"

FOREIGN KEYS RECREATED:
├─ activities → listings    → dispatch_activities → listings
├─ activities → realtors    → dispatch_activities → realtors
├─ activities → staff       → dispatch_activities → staff
└─ agent_tasks → realtors   → dispatch_agent_tasks → realtors
```

---

### Backend (Python FastAPI)
```
NEW FILES:
├─ apps/backend/api/routers/dispatch.py       (new namespace endpoints)
├─ apps/backend/api/routers/operations.py     (wrapped old endpoints)

UPDATED FILES:
├─ apps/backend/api/main.py                   (mount both routers)
├─ apps/backend/api/tools/database.py         (table name updates)
├─ apps/backend/api/workflows/slack_intake.py (table references)
├─ apps/backend/api/agents/classifier.py      (if writes to DB)
├─ apps/backend/api/config/settings.py        (Edge Config integration)

NEW ENDPOINTS:
├─ POST /intake/slack
├─ POST /intake/sms
├─ POST /reason/classify
├─ POST /reason/query
├─ POST /route/dispatch
├─ GET  /route/status/:id
├─ GET  /observe/health
├─ GET  /observe/agents
└─ GET  /observe/metrics
```

---

### Frontend (Swift)
```
TYPES RENAMED:
├─ AgentTask                → AgentMission
├─ TaskStatus               → MissionStatus
├─ TaskCategory             → MissionType
├─ TaskRepository           → MissionRepository
├─ TaskRepositoryClient     → MissionRepositoryClient
├─ AllTasksView             → AllMissionsView
├─ AllTasksStore            → AllMissionsStore
├─ MyTasksView              → MyMissionsView
├─ MyTasksStore             → MyMissionsStore
├─ TaskCard                 → MissionCard
├─ TaskToolbar              → MissionToolbar
├─ TaskRow                  → MissionRow
├─ TaskMockData             → MissionMockData
└─ TaskRepositoryTests      → MissionRepositoryTests

FILES RENAMED:
├─ AgentTask.swift          → AgentMission.swift
├─ TaskWithMessages.swift   → MissionWithMessages.swift
├─ TaskCard.swift           → MissionCard.swift
├─ TaskToolbar.swift        → MissionToolbar.swift
├─ TaskRow.swift            → MissionRow.swift
├─ TaskMockData.swift       → MissionMockData.swift
└─ TaskRepositoryTests.swift → MissionRepositoryTests.swift

FOLDERS RENAMED:
├─ AllTasks/                → AllMissions/
├─ MyTasks/                 → MyMissions/
└─ Tasks/                   → Missions/

CODINGKEYS UPDATED:
├─ "task_id"                → "mission_id"
├─ "task_category"          → "mission_type"
└─ "task_status"            → "mission_status"

FILE HEADERS UPDATED:
└─ //  Operations Center    → //  Dispatch  (all Swift files)
```

---

### Configuration
```
ENVIRONMENT VARIABLES:
├─ VERCEL_EDGE_CONFIG_ID    (new, for routing)
├─ API_VERSION              (new, default: "dispatch")

EDGE CONFIG VALUES:
└─ { "api_version": "dispatch", "api_base": "/dispatch" }

VERCEL.JSON:
└─ (No changes required - FastAPI handles routing internally)
```

---

## TIMELINE

| Phase | Duration | Owner | Blocker |
|-------|----------|-------|---------|
| **Phase 1: Foundation** | **1-2 weeks** | | |
| 1.1 DB Migration Design | 2 days | Backend | None |
| 1.2 Vercel Endpoint Setup | 3 days | Backend | None |
| 1.3 API Contract Design | 2 days | Backend + Mobile | None |
| 1.4 Testing in Staging | 3-5 days | QA | 1.1, 1.2, 1.3 complete |
| **Phase 2: Execution** | **2-3 weeks** | | |
| 2.1 Swift Refactor | 8-14 hours | Mobile | Phase 1 DB schema ready |
| 2.2 Python Updates | 4-6 hours | Backend | 2.1 complete |
| 2.3 Integration Testing | 3-5 days | QA | 2.1, 2.2 complete |
| **Phase 3: Cut-Over** | **2 hours** | | |
| 3.1 Pre-Flight Checks | 1 hour | All | Phase 1, 2 complete |
| 3.2 Production Switch | 1 hour | DevOps | 3.1 complete |
| 3.3 Monitoring | 30 min | On-call | 3.2 complete |
| **Total** | **3-5 weeks** | | |

---

## RISK ASSESSMENT

### HIGH RISK
- **Swift refactor scale:** 108+ type references, 129 function names. Missing one breaks compilation.
  - **Mitigation:** Incremental commits, build after every batch, comprehensive grep verification.

- **Database FK lock timeouts:** Adding constraints on heavily-used tables can queue locks.
  - **Mitigation:** `lock_timeout = 5s`, execute during quiet hours (3-4 AM), retry if fails.

### MEDIUM RISK
- **RLS policies not following renamed tables:** Policies are table-specific, must be explicitly recreated.
  - **Mitigation:** Verification queries after each migration step, automated testing.

- **CodingKeys mismatch:** Swift expecting `mission_id`, database still has `task_id`.
  - **Mitigation:** Coordinate Swift deploy AFTER database switch, test in staging first.

### LOW RISK
- **Vercel routing:** Edge Config flip is instant and has rollback.
  - **Mitigation:** Test both endpoint sets in preview, verify rollback works before production.

- **String literals in code:** Low impact if missed (doesn't affect compilation).
  - **Mitigation:** Find & Replace with manual review.

---

## SUCCESS CRITERIA

### Phase 1 Complete When:
- [ ] Both `/operations` and `/dispatch` endpoints live in production
- [ ] Staging database migrated successfully (24+ hours stable)
- [ ] Edge Config created and tested
- [ ] All tests pass in preview environment

### Phase 2 Complete When:
- [ ] Swift codebase compiles clean (zero Task references remain)
- [ ] All tests pass (iOS + macOS)
- [ ] TestFlight build deployed and verified
- [ ] Python backend updated and tested

### Phase 3 Complete When:
- [ ] Production database switched (old tables deprecated)
- [ ] Edge Config pointing to `/dispatch`
- [ ] Zero error rate increase (< 0.001% delta)
- [ ] Query latency within ±10% of baseline
- [ ] Deprecated tables dropped after 30+ min stability
- [ ] Operations Center is history. Dispatch is production.

---

## THE PHILOSOPHY

This isn't about renaming variables. It's about *clarity of purpose*.

"Operations Center" is a *place*. It's passive. It's bureaucratic.

**Dispatch** is *action*. It's intelligence in motion.

Every line of code should say: "We see. We think. We route."

When this transformation is complete, developers reading the API won't need documentation. They'll see `/intake`, `/reason`, `/route`, `/observe` and immediately understand.

That's when it becomes insanely great.

---

## FINAL CHECKLIST

Before you write one line of code:

- [ ] This blueprint reviewed and approved
- [ ] Database migration scripts drafted
- [ ] API contract endpoints designed
- [ ] Swift refactor plan documented
- [ ] Rollback procedures tested
- [ ] Team aligned on timeline
- [ ] Monitoring dashboards prepared
- [ ] Communication plan for users (if applicable)

**Now execute. One phase at a time. No shortcuts. Ship Dispatch.**
