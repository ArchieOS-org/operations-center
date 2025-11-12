# Final Architecture: Two APIs, Clear Separation

## The Architecture in One Diagram

```
┌─────────────────────────────────────────┐
│         SwiftUI Apps                     │
│     (macOS + iOS)                        │
└────────┬─────────────────┬───────────────┘
         │                 │
         │ 90% of calls    │ 10% of calls
         │                 │
         ↓                 ↓
┌──────────────────┐  ┌───────────────────┐
│   Supabase       │  │  FastAPI Agents   │
│                  │  │                   │
│ • Auto REST API  │  │ • POST /classify  │
│ • Real-time      │  │ • POST /chat      │
│ • Auth           │  │ • GET /status     │
│ • Storage        │  │                   │
│ • RLS            │  │ Streaming SSE     │
│                  │  │ + Background      │
│ ALL CRUD HERE    │  │ Workers           │
└──────────────────┘  └───────────────────┘
         ↑                     ↓
         └─────────────────────┘
           (Agents write to DB)
```

## Key Principle: Two APIs, Clear Separation

### **API #1: Supabase (Data)**
- **What:** PostgreSQL with auto-generated REST API
- **Used for:** ALL CRUD operations
- **Examples:**
  ```swift
  // Read
  let staff = try await supabase.from("staff").select()

  // Create
  try await supabase.from("tasks").insert(task)

  // Update
  try await supabase.from("realtors").update(data).eq("id", id)

  // Real-time
  await supabase.channel("changes").on("postgres_changes") { ... }
  ```
- **No Python code needed**

### **API #2: FastAPI (Agents)**
- **What:** Minimal Python backend (3 endpoints)
- **Used for:** AI/Agent operations ONLY
- **Examples:**
  ```swift
  // Interactive: User clicks button
  for try await chunk in agentClient.stream("/classify", body: data) {
    // Show streaming classification
  }

  // Interactive: User chats with AI
  for try await chunk in agentClient.stream("/chat", body: messages) {
    // Display streaming response
  }
  ```
- **60 lines of Python total**

## Two Agent Patterns

### **Pattern 1: Interactive (User-Triggered)**
```
User Action → FastAPI → Streaming Response
```
- User clicks "Classify Message"
- FastAPI streams response in real-time
- <500ms first token
- UI updates progressively

### **Pattern 2: Autonomous (Background)**
```
Database Event → Background Worker → Database Update
```
- Slack message arrives
- Background worker sees event
- Processes with LangGraph
- Writes result to database
- No API call needed

## What This Means for Development

### **For CRUD Operations**
❌ **Don't:** Write FastAPI endpoints
✅ **Do:** Use Supabase SDK directly

### **For Agent Operations**
❌ **Don't:** Poll database for responses
✅ **Do:** Stream from FastAPI endpoint

### **For Background Automation**
❌ **Don't:** Create API endpoints
✅ **Do:** Watch database events

## The Simplified Backend

```python
# main.py - The ENTIRE FastAPI backend

from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import asyncio

app = FastAPI()

# 3 endpoints total
@app.post("/classify")
async def classify(message: str):
    """Stream classification"""
    async def generate():
        async for chunk in classifier_agent.astream(...):
            yield f"data: {chunk}\n\n"
    return StreamingResponse(generate())

@app.post("/chat")
async def chat(messages: list):
    """Stream chat responses"""
    async def generate():
        async for chunk in chat_agent.astream(...):
            yield f"data: {chunk}\n\n"
    return StreamingResponse(generate())

@app.get("/status")
async def status():
    return {"status": "operational"}

# Background workers
@app.on_event("startup")
async def startup():
    asyncio.create_task(watch_database_events())
```

## Why This Architecture

1. **Simplicity**
   - Supabase handles all CRUD (no code to write)
   - FastAPI only does agents (60 lines)

2. **Performance**
   - Direct database access (faster)
   - Streaming for interactive agents

3. **Scalability**
   - Add agents without adding endpoints
   - Scale data and agents independently

4. **Cost**
   - Supabase: ~$25/month
   - FastAPI on Railway: ~$5-20/month
   - Total: <$50/month

## Migration Path

### **Week 1: Setup**
1. Keep existing database (9 migrations)
2. Enable Supabase auto-generated API
3. Add SwiftUI Supabase SDK

### **Week 2: Simplify**
1. Delete 52 CRUD endpoints from FastAPI
2. Delete database access layer
3. Keep only classifier.py

### **Week 3: Enhance**
1. Add streaming endpoints (3 total)
2. Add background workers
3. Deploy to Railway/Render

## Future Growth

### **Year 1 (Now):**
```
2 agents → 3 endpoints
```

### **Year 2 (Planned):**
```
10+ agents → Still 3-5 endpoints
(Agents called through orchestrator)
```

### **Year 3 (Vision):**
```
50+ agents → Still 3-5 endpoints
(Hierarchical multi-agent system)
```

## The Bottom Line

- **Two APIs:** Supabase for data, FastAPI for agents
- **Clear rule:** If it's CRUD, use Supabase. If it's AI, use FastAPI.
- **Two patterns:** Interactive (streaming) vs Autonomous (background)
- **One principle:** Keep them separate

This architecture will scale from 2 agents to 200 without fundamental changes.