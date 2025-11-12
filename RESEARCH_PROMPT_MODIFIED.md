# Prompt: Evidence-Based Guidance for a SwiftUI Frontend (macOS, iOS) with Existing Python FastAPI + Supabase Backend — **Claude Code–First**, Real-Estate Operations Management with AI Classification

## Role & Lens

Act as a principal Apple-platform architect **and** expert **Claude Code** operator. Produce **actionable guidance** (not long code) for building a clean, scalable SwiftUI frontend for **macOS and iOS**—connecting to an **existing Python FastAPI backend** that manages real-estate operations with AI-powered message classification.

## Research Requirements (Deep Web Search)

Do **not** rely solely on prior training. Perform **deep, current web research** across:
- Apple HIG/SwiftUI for enterprise/productivity apps
- FastAPI + SwiftUI integration patterns
- Supabase SDK for Swift (Auth/Postgres/Storage/RLS/Realtime)
- **Claude Code** docs/workflows
- LangChain integration patterns for frontends
- Slack webhook handling in Swift
- Real-estate operations domain patterns

- **Freshness:** Prefer sources from the last **18 months**; include publish date.
- **Citations:** Use **inline citations** `[Title – Site, YYYY-MM-DD](URL)` after relevant guidance, with a final **Sources & Notes** appendix.
- **Dates:** Start with "**As of <today's date>**" (timezone **America/Toronto**).
- **Transparency:** If evidence is thin or conflicting, say so and provide a safe default.

## Version Assumptions (Working with Existing Stack)

- **Backend:** Python 3.11+, FastAPI 0.115.13+, LangChain 0.3.0+, Supabase Python 2.10.0+
- **Frontend:** Swift 6.0, Xcode 16+, SwiftUI targeting macOS 14+/iOS 17+
- **Database:** Supabase (PostgreSQL 15) with **9 existing migrations**
- **Deployment:** Vercel serverless functions (backend already deployed)
- Assume **Apple 26** OS family and **"Liquid Glass."** Include **capability detection**, **feature flags**, and **fallbacks**.

## Hard Requirements (Key Clarifications)

- **Existing Backend:** Python FastAPI with **52 endpoints** across 5 routers (staff, realtors, listing_tasks, stray_tasks, slack_messages)
- **Platforms:** macOS (supervisor dashboard) and iOS (mobile operations)
- **Domain:** Real-estate operations management with:
  - Staff vs. Realtor distinction
  - Listing-specific and general task management
  - Slack message classification via LangChain
  - Multi-workspace/tenant support
- **AI Integration:** Display LangChain classification results, confidence scores
- **Real-time updates:** Leverage existing Supabase for instant sync
- **Offline-first:** Works offline; changes reconcile with FastAPI backend
- **Security:** JWT auth, RLS policies, workspace isolation already in place

## Context (Current Implementation)

- **Backend (COMPLETE):**
  - Python FastAPI with 52 RESTful endpoints
  - Pydantic v2 models (Staff, Realtor, ListingTask, StrayTask, SlackMessage)
  - LangChain classifier for message processing
  - Supabase database with 9 migrations
  - JWT authentication middleware
  - Slack webhook integration
  - Vercel deployment configuration

- **Database Schema (EXISTING):**
  - `tasks`, `task_notes`, `listings` (original tables)
  - `staff`, `realtors` (user management)
  - `listing_tasks`, `stray_tasks` (task separation)
  - `slack_messages` (AI classification tracking)
  - All with soft delete, ULID primary keys, JSONB metadata

- **Frontend (TO BUILD):** SwiftUI connecting to existing APIs

## Goals

1. Define **hybrid architecture**: SwiftUI frontend ↔ FastAPI backend communication patterns
2. Create **Swift models** matching existing Pydantic schemas
3. Design **API client layer** with OpenAPI integration or manual URLSession
4. Build **real-time sync** using existing Supabase alongside REST APIs
5. Implement **task management UI** for supervisors (macOS) and field staff (iOS)
6. Display **AI classification results** from LangChain with confidence visualization
7. Handle **Slack message workflows** initiated from backend webhooks
8. Provide **Claude Code–centric workflows** for frontend development

## Non-Goals & Guardrails

- Do **not** rewrite the Python backend (it's production-ready)
- Do **not** bypass existing JWT auth or RLS policies
- Focus on **frontend architecture** that complements existing backend
- Keep backend API calls through FastAPI, use Supabase for realtime only

-----

## What to Deliver

### 1) Claude Code–First Operating Mode for Hybrid Stack

Explain how to run the **frontend project** with awareness of existing backend:

- **Repository structure** acknowledging `backend/`, `migrations/`, existing configs
- A **`apps/CLAUDE.md`** for frontend development that references backend endpoints
- **API documentation sync**: How to keep Swift models aligned with Pydantic
- **`.claude/`** structure for Swift-specific commands:
  - `/generate-api-client` (from OpenAPI spec)
  - `/sync-models` (update Swift from Pydantic)
  - `/test-integration` (frontend + backend tests)
- **Development workflow**: Running backend locally + Swift frontend
- Provide templates for API integration testing and model synchronization

### 2) Architecture & Frontend Structure

- **MVVM + Services** pattern for API integration:
  - ViewModels calling FastAPI endpoints
  - Services layer for API client + Supabase realtime
  - Repository pattern for data access
- Proposed modules:
  - `OperationsCenterKit` (shared business logic)
  - `APIClient` (FastAPI integration)
  - `RealtimeKit` (Supabase subscriptions)
  - `StaffDashboard` (macOS app)
  - `FieldOperations` (iOS app)
  - `DesignSystem` (shared UI components)
- **State management** for:
  - Task lists with real-time updates
  - Slack message queue processing
  - Classification confidence display

### 3) API Integration Layer

- **Swift models** matching existing Pydantic schemas:
  ```swift
  // Mirror backend/models/staff.py
  struct Staff: Codable {
      let id: String // ULID
      let email: String
      let role: StaffRole
      let status: StaffStatus
      // ...
  }
  ```
- **API Client** architecture:
  - OpenAPI-generated vs manual implementation trade-offs
  - Error handling for FastAPI responses
  - JWT token management and refresh
- **Endpoint mapping** for 52 existing endpoints
- **Pagination** handling (limit/offset pattern)

### 4) Real-Estate Operations UI/UX

- **macOS Supervisor Dashboard:**
  - Multi-pane layout (messages, tasks, staff assignments)
  - Slack message classification queue
  - Real-time task status updates
  - Staff performance metrics

- **iOS Field Operations:**
  - Task list by realtor/listing
  - Quick task creation/completion
  - Photo attachment for property tasks
  - Offline task queue

- **Shared Components:**
  - TaskRow (with status, category, assignee)
  - MessageCard (with AI classification display)
  - StaffSelector, RealtorSelector
  - ConfidenceIndicator (for AI results)

### 5) Data Synchronization Strategy

- **Hybrid approach:**
  - CRUD operations via FastAPI endpoints
  - Real-time updates via Supabase subscriptions
  - Conflict resolution respecting backend as source of truth

- **Caching strategy:**
  - SwiftData for offline storage
  - Sync queue for pending operations
  - Background refresh from FastAPI

- **WebSocket integration:**
  - Subscribe to relevant Supabase channels
  - Handle backend-initiated updates (Slack webhook → task creation)

### 6) AI Classification Display

- **LangChain results visualization:**
  - Confidence scores with visual indicators
  - Classification type badges (new_listing, inquiry, etc.)
  - Extracted fields highlighting
  - Manual override UI for supervisors

- **Message processing flow:**
  - Display pending Slack messages
  - Show classification in progress
  - Present results for review
  - Create tasks from classified messages

### 7) Testing Strategy for Hybrid Architecture

- **Integration tests:**
  - Mock FastAPI server for UI testing
  - Test data generators matching Pydantic models
  - Slack webhook simulation

- **API contract testing:**
  - Ensure Swift models match Pydantic schemas
  - Validate endpoint request/response formats
  - Test pagination and filtering

### 8) CI/CD for Frontend + Backend

- **Monorepo considerations:**
  - Keep existing Python CI/CD
  - Add Swift CI in parallel
  - Shared environment variables
  - Coordinated deployments

- **Development environments:**
  - Local: Python backend + Swift frontend
  - Staging: Vercel backend + TestFlight apps
  - Production: Full stack deployment

### 9) Migration Path from Web UI (if exists)

- **Feature parity checklist**
- **Data migration considerations**
- **User training materials**
- **Rollback procedures**

### 10) Deliverables & Templates

- **API Integration templates:**
  - APIClient protocol
  - Model synchronization script
  - Error handling patterns

- **UI Templates:**
  - Task management views
  - Message classification interface
  - Staff assignment flows

- **Documentation:**
  - API endpoint mapping table
  - State management diagrams
  - Deployment runbooks

### 11) First Three Work Orders

1. **Create APIClient package:** Connect to existing `/v1/operations/*` endpoints with JWT auth
2. **Build task list view:** Display listing_tasks and stray_tasks with real-time updates
3. **Implement Slack message queue:** Show pending messages with AI classification results

### 12) Risk Register & Mitigations

- **API version drift:** Backend changes breaking Swift models → automated contract testing
- **Realtime lag:** Supabase subscription delays → fallback polling
- **Offline conflicts:** Conflicting task updates → backend wins, user notification
- **Classification errors:** Wrong AI categorization → manual override UI
- **Auth token expiry:** JWT refresh failures → re-authentication flow

### 13) Sources & Notes (Research Appendix)

List all sources focusing on:
- FastAPI + SwiftUI integration patterns
- Supabase Swift SDK with existing backend
- Real-estate/operations management UX patterns
- LangChain result visualization
- Slack integration in Swift
- Hybrid architecture best practices

-----

## Output Format

- Start with **"As of <today's date> (America/Toronto)"**
- Acknowledge **existing Python backend with 52 endpoints**
- Focus on **frontend architecture that complements** rather than replaces
- Include **API integration patterns** prominently
- Provide **migration paths** from current workflow

## Success Criteria

I can build a SwiftUI frontend that:
- **Connects to all 52 existing FastAPI endpoints**
- **Displays real-time updates** via Supabase subscriptions
- **Shows AI classification results** from LangChain processing
- **Manages tasks** for both staff and realtors
- **Works offline** and syncs when connected
- **Integrates with existing** JWT auth and RLS policies
- **Complements rather than replaces** the production Python backend