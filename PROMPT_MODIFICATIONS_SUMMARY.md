# Key Modifications to Research Prompt

## Summary of Changes
Modified the prompt from a **greenfield SwiftUI + Supabase app** to a **SwiftUI frontend for existing Python FastAPI backend** in a real-estate operations domain.

## Major Differences

### 1. **Project Context**
**Original:**
- Greenfield SwiftUI app with Things 3-inspired UI
- Direct Supabase integration for all operations
- Generic productivity app

**Modified:**
- SwiftUI frontend for **existing Python FastAPI backend**
- Real-estate operations management system
- **52 existing endpoints** across 5 routers
- AI-powered message classification with LangChain
- Slack integration already implemented

### 2. **Technology Stack**
**Original:**
- SwiftUI ↔ Supabase (direct)
- No backend mentioned
- Focus on real-time everything

**Modified:**
- SwiftUI ↔ FastAPI (primary) + Supabase (realtime only)
- Python 3.11, FastAPI 0.115.13, LangChain 0.3.0
- Pydantic v2 models already defined
- JWT auth middleware in place
- 9 database migrations already applied

### 3. **Architecture Focus**
**Original:**
- Pure SwiftUI architecture (MVVM vs TCA debate)
- Greenfield design decisions
- Direct database access

**Modified:**
- **Hybrid architecture** patterns
- API client layer design
- Model synchronization (Pydantic ↔ Swift)
- Backend as source of truth
- Integration testing focus

### 4. **Domain Specifics**
**Original:**
- Generic tasks/projects/areas
- Abstract productivity concepts

**Modified:**
- **Staff vs Realtors** distinction
- **Listing tasks vs Stray tasks**
- **Slack message classification**
- Real-estate specific workflows
- Supervisor dashboard vs field operations

### 5. **Development Approach**
**Original:**
- Claude Code creates everything
- Full control over backend
- Schema design from scratch

**Modified:**
- Claude Code for **frontend only**
- Respect existing backend APIs
- Work with existing schemas
- API contract testing emphasis

### 6. **Key Requirements Added**

1. **API Integration Layer**
   - Swift models matching Pydantic schemas
   - OpenAPI integration considerations
   - 52 endpoint mapping

2. **AI Classification Display**
   - LangChain results visualization
   - Confidence score UI
   - Message processing workflows

3. **Hybrid Data Sync**
   - CRUD via FastAPI
   - Realtime via Supabase
   - Offline queue management

4. **Testing Strategy**
   - API contract validation
   - Mock FastAPI server
   - Integration test focus

### 7. **Deliverables Shift**
**Original:**
- Full-stack templates
- Database migrations
- Backend setup

**Modified:**
- API client templates
- Model sync scripts
- Frontend-specific components
- Integration patterns

### 8. **First Work Orders**
**Original:**
1. Design system from scratch
2. Create Supabase schema
3. Setup realtime channels

**Modified:**
1. Create APIClient for existing endpoints
2. Display existing task types
3. Show Slack classification queue

### 9. **Risk Focus**
**Original:**
- Realtime performance
- Conflict resolution
- Schema migrations

**Modified:**
- API version drift
- Model synchronization
- Backend compatibility
- Classification accuracy display

### 10. **Research Topics**
**Original:**
- Supabase best practices
- Things 3 UI patterns
- Offline-first strategies

**Modified:**
- FastAPI + SwiftUI integration
- Pydantic ↔ Swift model mapping
- LangChain visualization patterns
- Real-estate operations UX

## Why These Changes Matter

1. **Reflects Reality**: The project already has a production-ready Python backend
2. **Preserves Investment**: Leverages existing 52 endpoints and business logic
3. **Domain-Specific**: Addresses real-estate operations, not generic productivity
4. **Integration-First**: Focuses on connecting systems vs building from scratch
5. **AI-Aware**: Incorporates the LangChain classification feature prominently
6. **Practical**: Acknowledges existing auth, RLS, and database structure

## Recommended Research Areas

Based on the modifications, prioritize research on:

1. **FastAPI ↔ SwiftUI Communication**
   - OpenAPI code generation for Swift
   - JWT handling in URLSession
   - Error response mapping

2. **Model Synchronization**
   - Automated Pydantic → Swift Codable conversion
   - Handling JSONB fields
   - ULID support in Swift

3. **Hybrid Architecture Patterns**
   - When to use REST vs WebSocket
   - Caching strategies for API responses
   - Offline queue with FastAPI backend

4. **AI Results Visualization**
   - Confidence score UI patterns
   - Classification result displays
   - Manual override interfaces

5. **Real-Estate Operations UX**
   - Task management for property maintenance
   - Multi-location staff coordination
   - Supervisor vs field worker interfaces

This modified prompt will generate guidance that's immediately applicable to your existing Operations Center v2.0 project rather than theoretical greenfield advice.