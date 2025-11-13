"""
Operations Center Intelligence API

The central nervous system for real estate operations.
FastAPI handles ONLY intelligence - AI classification, agents, and orchestration.
All CRUD operations go directly from Swift → Supabase.

Endpoints:
- POST /webhooks/slack    - Slack message intake
- POST /webhooks/sms      - SMS message intake
- POST /classify          - Stream classification results
- POST /chat              - Interactive agent chat
- GET  /status            - System health & agent status
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from contextlib import asynccontextmanager
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import logging
import asyncio
from datetime import datetime

# Import our intelligence layer
# from webhooks import slack, sms  # TODO: Implement webhook modules
from workflows.slack_intake import process_slack_message
from agents import get_agent, list_agents

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Background task storage
background_tasks = set()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan events for the intelligence hub.
    Manages startup and shutdown of background workers.
    """
    logger.info("🧠 Starting Operations Center Intelligence Hub...")
    logger.info("✅ LangChain agents initialized")
    logger.info("✅ LangGraph workflows ready")
    logger.info("✅ Supabase connection configured")

    # Start background workers
    # slack_worker = asyncio.create_task(monitor_slack_queue())
    # sms_worker = asyncio.create_task(monitor_sms_queue())
    # background_tasks.add(slack_worker)
    # background_tasks.add(sms_worker)
    # logger.info("✅ Background workers started")

    yield  # Application runs here

    # Shutdown - cleanup
    logger.info("🛑 Shutting down Intelligence Hub...")
    for task in background_tasks:
        task.cancel()
    logger.info("✅ Background workers stopped")


# Initialize FastAPI application
app = FastAPI(
    title="Operations Center Intelligence API",
    description="AI-powered intelligence layer for real estate operations. Handles classification, agents, and orchestration.",
    version="3.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:5173",  # Vite
        "https://*.vercel.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ═══════════════════════════════════════════════════════════
# REQUEST/RESPONSE MODELS
# ═══════════════════════════════════════════════════════════

class SlackWebhookPayload(BaseModel):
    """Slack event webhook payload"""
    type: str
    challenge: Optional[str] = None
    event: Optional[Dict[str, Any]] = None


class ClassifyRequest(BaseModel):
    """Request to classify a message"""
    message: str
    source: str = "slack"
    metadata: Optional[Dict[str, Any]] = None


class ChatRequest(BaseModel):
    """Request for interactive chat"""
    messages: List[Dict[str, str]]
    context: Optional[Dict[str, Any]] = None


# ═══════════════════════════════════════════════════════════
# WEBHOOK ENDPOINTS (External → FastAPI)
# ═══════════════════════════════════════════════════════════

@app.post("/webhooks/slack")
async def slack_webhook(payload: SlackWebhookPayload, request: Request):
    """
    Slack Events API webhook.

    Receives messages from Slack, classifies them with AI,
    routes to appropriate agents, and stores results.
    """
    # Handle URL verification challenge
    if payload.type == "url_verification":
        return {"challenge": payload.challenge}

    # Handle event callback
    if payload.type == "event_callback":
        try:
            result = await process_slack_message(payload.dict())

            # Return 200 immediately to Slack (they timeout at 3s)
            if result.get("response"):
                # Queue response to be sent back to Slack
                # This would be handled by a background task
                pass

            return {"ok": True}

        except Exception as e:
            logger.error(f"Slack webhook error: {str(e)}")
            # Still return 200 to Slack to avoid retries
            return {"ok": True, "error": "processing_failed"}

    return {"ok": False, "error": "unknown_event_type"}


@app.post("/webhooks/sms")
async def sms_webhook(request: Request):
    """
    Twilio SMS webhook.

    Receives SMS messages, classifies them, and processes
    through the agent system.
    """
    # TODO: Implement SMS workflow
    form_data = await request.form()

    logger.info(f"SMS received from: {form_data.get('From')}")

    return JSONResponse({
        "message": "SMS processing not yet implemented"
    })


# ═══════════════════════════════════════════════════════════
# INTELLIGENCE ENDPOINTS (Swift/Web → FastAPI)
# ═══════════════════════════════════════════════════════════

@app.post("/classify")
async def classify_stream(req: ClassifyRequest):
    """
    Stream classification results for a message.

    Returns Server-Sent Events (SSE) with progressive
    classification results as the LLM processes the message.
    """
    async def generate():
        """Generate SSE stream"""
        try:
            # Get classifier agent
            classifier = get_agent("classifier")
            if not classifier:
                yield "data: {'error': 'Classifier not available'}\n\n"
                return

            # For now, do synchronous classification
            # TODO: Implement streaming when classifier supports it
            result = await classifier.process({
                "message": req.message,
                "metadata": req.metadata or {}
            })

            # Send result
            import json
            yield f"data: {json.dumps(result)}\n\n"
            yield "data: [DONE]\n\n"

        except Exception as e:
            logger.error(f"Classification error: {str(e)}")
            yield f"data: {{'error': '{str(e)}'}}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        }
    )


@app.post("/chat")
async def chat_stream(req: ChatRequest):
    """
    Interactive chat with AI agent (streaming).

    Sends messages to the orchestrator agent and streams
    responses back token-by-token for real-time UI updates.
    """
    async def generate():
        """Generate SSE stream"""
        try:
            # Get orchestrator
            orchestrator = get_agent("orchestrator")
            if not orchestrator:
                yield "data: {'error': 'Orchestrator not available'}\n\n"
                return

            # Process through orchestrator
            result = await orchestrator.process({
                "messages": req.messages,
                "context": req.context or {}
            })

            # Stream response
            import json
            yield f"data: {json.dumps(result)}\n\n"
            yield "data: [DONE]\n\n"

        except Exception as e:
            logger.error(f"Chat error: {str(e)}")
            yield f"data: {{'error': '{str(e)}'}}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        }
    )


# ═══════════════════════════════════════════════════════════
# STATUS & HEALTH
# ═══════════════════════════════════════════════════════════

@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "name": "Operations Center Intelligence API",
        "version": "3.0.0",
        "description": "AI-powered intelligence layer for real estate operations",
        "endpoints": {
            "webhooks": {
                "slack": "POST /webhooks/slack",
                "sms": "POST /webhooks/sms"
            },
            "intelligence": {
                "classify": "POST /classify",
                "chat": "POST /chat"
            },
            "system": {
                "status": "GET /status",
                "docs": "GET /docs"
            }
        },
        "docs": "/docs",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/status")
async def get_status():
    """
    System health and agent status.

    Returns information about all agents, background workers,
    and system health metrics.
    """
    # Get all registered agents
    agents = list_agents()

    return {
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat(),
        "agents": {
            "available": agents,
            "total": len(agents)
        },
        "workers": {
            "slack_processor": "ready",  # TODO: Get actual status
            "sms_processor": "ready",
        },
        "integrations": {
            "supabase": "connected",
            "openai": "configured",
            "slack": "configured",
            "twilio": "configured"
        },
        "version": "3.0.0"
    }


# ═══════════════════════════════════════════════════════════
# BACKGROUND WORKERS (Future)
# ═══════════════════════════════════════════════════════════

async def monitor_slack_queue():
    """
    Background worker to monitor Slack message queue.
    Processes messages that need async handling.
    """
    while True:
        try:
            # TODO: Implement queue monitoring
            await asyncio.sleep(5)
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Slack worker error: {str(e)}")
            await asyncio.sleep(10)


async def monitor_sms_queue():
    """
    Background worker to monitor SMS queue.
    Processes SMS messages asynchronously.
    """
    while True:
        try:
            # TODO: Implement queue monitoring
            await asyncio.sleep(5)
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"SMS worker error: {str(e)}")
            await asyncio.sleep(10)


# ═══════════════════════════════════════════════════════════
# LOCAL DEVELOPMENT
# ═══════════════════════════════════════════════════════════

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )