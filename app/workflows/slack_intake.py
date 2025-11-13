"""
Slack Message Intake Workflow

Complete pipeline for processing incoming Slack messages:
1. Receive message from webhook
2. Classify with AI
3. Store in database
4. Route to appropriate agent
5. Send response back to Slack
"""

from typing import Dict, Any, Optional
from langgraph.graph import StateGraph, END, START
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict, Annotated
import logging

from agents import get_agent
from database.supabase_client import get_supabase
from schemas.classification import ClassificationV1
from .entity_creation import create_entities_from_classification

logger = logging.getLogger(__name__)


class SlackWorkflowState(TypedDict):
    """State for Slack message processing workflow"""
    messages: Annotated[list, add_messages]
    slack_event: Dict[str, Any]
    classification: Optional[Dict[str, Any]]
    entity_result: Optional[Dict[str, Any]]
    agent_result: Optional[Dict[str, Any]]
    response: Optional[str]
    error: Optional[str]
    slack_message_id: Optional[str]


def build_slack_workflow() -> StateGraph:
    """Build the Slack message processing workflow"""

    workflow = StateGraph(SlackWorkflowState)

    # Define nodes
    workflow.add_node("validate", validate_slack_event)
    workflow.add_node("classify", classify_message)
    workflow.add_node("store", store_in_database)
    workflow.add_node("create_entities", create_entities_node)
    workflow.add_node("route", route_to_agent)
    workflow.add_node("respond", prepare_response)
    workflow.add_node("error", handle_error)

    # Define edges
    workflow.add_edge(START, "validate")

    # Validation can succeed or fail
    workflow.add_conditional_edges(
        "validate",
        lambda state: "classify" if not state.get("error") else "error",
        {
            "classify": "classify",
            "error": "error"
        }
    )

    workflow.add_edge("classify", "store")
    workflow.add_edge("store", "create_entities")
    workflow.add_edge("create_entities", "route")
    workflow.add_edge("route", "respond")
    workflow.add_edge("respond", END)
    workflow.add_edge("error", END)

    return workflow.compile()


async def validate_slack_event(state: SlackWorkflowState) -> SlackWorkflowState:
    """
    Validate the incoming Slack event.

    Checks:
    - Event structure is valid
    - Message text exists
    - Not a bot message
    - Not a duplicate
    """
    event = state.get("slack_event", {})

    # Check for required fields
    if not event:
        return {
            **state,
            "error": "No Slack event provided"
        }

    # Extract message details
    event_data = event.get("event", {})
    message_text = event_data.get("text", "")
    user = event_data.get("user", "")
    channel = event_data.get("channel", "")
    ts = event_data.get("ts", "")

    # Skip bot messages
    if event_data.get("bot_id"):
        return {
            **state,
            "error": "Bot message - skipping"
        }

    # Check for required fields
    if not message_text or not user or not channel:
        return {
            **state,
            "error": "Missing required fields in Slack event"
        }

    logger.info(f"Valid Slack message from {user} in {channel}: {message_text[:100]}")

    # Add to messages for processing
    return {
        **state,
        "messages": [{
            "role": "user",
            "content": message_text,
            "metadata": {
                "user": user,
                "channel": channel,
                "ts": ts
            }
        }]
    }


async def classify_message(state: SlackWorkflowState) -> SlackWorkflowState:
    """Classify the message using the classifier agent"""

    try:
        classifier = get_agent("classifier")
        if not classifier:
            return {
                **state,
                "error": "Classifier agent not available"
            }

        # Get the message text
        message = state["messages"][0] if state.get("messages") else {}
        message_text = message.get("content", "")

        # Classify
        classification_result = await classifier.process({
            "message": message_text,
            "metadata": message.get("metadata", {})
        })

        logger.info(f"Classification result: {classification_result.get('message_type')}")

        return {
            **state,
            "classification": classification_result
        }

    except Exception as e:
        logger.error(f"Classification failed: {str(e)}")
        return {
            **state,
            "error": f"Classification failed: {str(e)}"
        }


async def store_in_database(state: SlackWorkflowState) -> SlackWorkflowState:
    """Store the message and classification in the database"""

    try:
        event = state.get("slack_event", {})
        event_data = event.get("event", {})
        classification = state.get("classification", {})

        # Create message record
        client = get_supabase()
        message_data = {
            "message_text": event_data.get("text", ""),
            "user_id": event_data.get("user", ""),
            "channel_id": event_data.get("channel", ""),
            "timestamp": event_data.get("ts", ""),
            "classification": classification,
            "processing_status": "classified"
        }

        result = client.table("slack_messages").insert(message_data).execute()

        if result.data:
            message_id = result.data[0].get("id")
            logger.info(f"Stored Slack message with ID: {message_id}")
            state["slack_message_id"] = message_id

    except Exception as e:
        logger.error(f"Failed to store in database: {str(e)}")
        # Continue processing even if storage fails

    return state


async def create_entities_node(state: SlackWorkflowState) -> SlackWorkflowState:
    """
    Create database entities (listings/tasks) from classification.

    Context7 Pattern: LangGraph node - async function that returns dict updates
    Source: /websites/langchain-ai_github_io_langgraph node patterns
    """
    try:
        classification_dict = state.get("classification", {})
        message_id = state.get("slack_message_id")
        message_text = state.get("messages", [{}])[0].get("content", "")

        if not classification_dict or not message_id:
            logger.warning("Missing classification or message_id - skipping entity creation")
            return state

        # Convert dict to ClassificationV1 Pydantic model
        classification = ClassificationV1(**classification_dict)

        # Call entity creation logic
        entity_result = await create_entities_from_classification(
            classification=classification,
            message_id=message_id,
            message_text=message_text
        )

        logger.info(f"Entity creation result: {entity_result.get('status')}")

        return {
            **state,
            "entity_result": entity_result
        }

    except Exception as e:
        logger.error(f"Entity creation node failed: {str(e)}")
        return {
            **state,
            "entity_result": {
                "status": "error",
                "reason": str(e)
            }
        }


async def route_to_agent(state: SlackWorkflowState) -> SlackWorkflowState:
    """Route the classified message to the appropriate agent"""

    try:
        classification = state.get("classification", {})
        message_type = classification.get("message_type")

        # Skip if message should be ignored
        if message_type == "IGNORE":
            logger.info("Message type is IGNORE - skipping agent processing")
            return {
                **state,
                "agent_result": {
                    "status": "ignored",
                    "message": "Message ignored per classification"
                }
            }

        # Use orchestrator to route to appropriate agent
        orchestrator = get_agent("orchestrator")
        if orchestrator:
            result = await orchestrator.process({
                "messages": state.get("messages", []),
                "classification": classification
            })

            return {
                **state,
                "agent_result": result
            }
        else:
            # Fallback if orchestrator not available
            return {
                **state,
                "agent_result": {
                    "status": "pending",
                    "message": "Agent processing not yet available"
                }
            }

    except Exception as e:
        logger.error(f"Agent routing failed: {str(e)}")
        return {
            **state,
            "error": f"Agent routing failed: {str(e)}"
        }


def prepare_response(state: SlackWorkflowState) -> SlackWorkflowState:
    """Prepare the response to send back to Slack"""

    classification = state.get("classification", {})
    agent_result = state.get("agent_result", {})

    message_type = classification.get("message_type", "UNKNOWN")
    status = agent_result.get("status", "processed")

    # Create appropriate response based on message type
    if message_type == "IGNORE":
        response = None  # Don't respond to ignored messages
    elif message_type == "INFO_REQUEST":
        explanations = classification.get("explanations", [])
        response = f"ℹ️ Additional information needed: {', '.join(explanations)}"
    elif status == "success":
        response = f"✅ {agent_result.get('message', 'Processed successfully')}"
    elif status == "pending":
        response = f"⏳ {agent_result.get('message', 'Task queued for processing')}"
    else:
        response = f"📋 Message received and classified as: {message_type}"

    return {
        **state,
        "response": response
    }


def handle_error(state: SlackWorkflowState) -> SlackWorkflowState:
    """Handle errors in the workflow"""

    error = state.get("error", "Unknown error")
    logger.error(f"Slack workflow error: {error}")

    # Don't send error details to Slack in production
    # Just log internally and return generic message
    return {
        **state,
        "response": None  # Don't respond on errors
    }


# Create and export the workflow
slack_workflow = build_slack_workflow()


async def process_slack_message(slack_event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Main entry point for processing a Slack message.

    Args:
        slack_event: Raw Slack event from webhook

    Returns:
        Processing result with optional response
    """
    result = await slack_workflow.ainvoke({
        "slack_event": slack_event,
        "messages": []
    })

    return {
        "success": not bool(result.get("error")),
        "response": result.get("response"),
        "classification": result.get("classification"),
        "error": result.get("error")
    }