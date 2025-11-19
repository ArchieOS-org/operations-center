"""
Orchestrator Agent - The Conductor

This agent routes messages to the appropriate specialist agents based on
classification results. It's the central coordinator of the multi-agent system.
"""

import logging
from typing import Dict, Any, Optional
from langgraph.graph import StateGraph, END, START
from langgraph.graph.state import CompiledStateGraph
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict, Annotated

from . import BaseAgent, get_agent

logger = logging.getLogger(__name__)


class OrchestratorState(TypedDict):
    """State for orchestrator workflow"""

    messages: Annotated[list, add_messages]
    classification: Optional[Dict[str, Any]]
    routing_decision: Optional[str]
    result: Optional[Dict[str, Any]]


class OrchestratorAgent(BaseAgent):
    """
    The Orchestrator - Routes messages to appropriate specialist agents.

    This is the conductor of our agent symphony. It:
    1. Receives classified messages
    2. Determines which specialist agent should handle them
    3. Coordinates the response
    4. Returns the result
    """

    def __init__(self):
        self.graph = self._build_graph()

    @property
    def name(self) -> str:
        return "orchestrator"

    @property
    def description(self) -> str:
        return (
            "Routes messages to appropriate specialist agents based on classification"
        )

    def _build_graph(self) -> CompiledStateGraph:
        """Build the orchestration workflow graph"""

        workflow = StateGraph(OrchestratorState)

        # Add nodes
        workflow.add_node("route", self._route_message)
        workflow.add_node("process_realtor", self._process_with_realtor_agent)
        workflow.add_node("process_listing", self._process_with_listing_agent)
        workflow.add_node("process_task", self._process_with_task_agent)
        workflow.add_node("process_generic", self._process_generic)

        # Add edges
        workflow.add_edge(START, "route")

        # Conditional routing based on classification
        workflow.add_conditional_edges(
            "route",
            self._get_routing_decision,
            {
                "realtor": "process_realtor",
                "listing": "process_listing",
                "task": "process_task",
                "generic": "process_generic",
                END: END,
            },
        )

        # All processing nodes lead to END
        workflow.add_edge("process_realtor", END)
        workflow.add_edge("process_listing", END)
        workflow.add_edge("process_task", END)
        workflow.add_edge("process_generic", END)

        return workflow.compile()

    async def process(self, input_data: dict) -> dict:
        """
        Process a classified message by routing to appropriate agent.

        Args:
            input_data: Must contain 'classification' from classifier agent

        Returns:
            Result from the specialist agent
        """
        if "classification" not in input_data:
            # First, classify the message
            classifier = get_agent("classifier")
            if classifier:
                classification_result = await classifier.process(input_data)
                input_data["classification"] = classification_result

        # Run the orchestration workflow
        result = await self.graph.ainvoke(
            {
                "messages": input_data.get("messages", []),
                "classification": input_data.get("classification"),
            }
        )

        return result.get("result", {})

    def _route_message(self, state: OrchestratorState) -> OrchestratorState:
        """Analyze classification and determine routing"""

        classification = state.get("classification") or {}

        # Determine which agent should handle this
        message_type = classification.get("message_type") or ""
        group_key = classification.get("group_key") or ""
        task_key = classification.get("task_key") or ""

        if message_type == "IGNORE":
            routing = END
        elif group_key and "LISTING" in group_key:
            routing = "listing"
        elif task_key and "REALTOR" in task_key:
            routing = "realtor"
        elif task_key:
            routing = "task"
        else:
            routing = "generic"

        logger.info(f"Routing decision: {routing} for message type: {message_type}")

        return {
            **state,
            "routing_decision": routing,
        }

    def _get_routing_decision(self, state: OrchestratorState) -> str:
        """Extract routing decision from state"""
        routing_decision = state.get("routing_decision")

        if not routing_decision:
            logger.warning(
                "routing_decision was missing or corrupted in state - "
                "falling back to conservative default 'generic'"
            )
            return "generic"

        return routing_decision

    async def _process_with_realtor_agent(
        self, state: OrchestratorState
    ) -> OrchestratorState:
        """Process with realtor specialist agent"""

        # TODO: Implement when RealtorAgent is created
        # realtor_agent = get_agent("realtor")
        # if realtor_agent:
        #     result = await realtor_agent.process(state)
        # else:
        result = {
            "status": "pending",
            "message": "Realtor agent not yet implemented",
            "classification": state.get("classification"),
        }

        return {
            **state,
            "result": result,
        }

    async def _process_with_listing_agent(
        self, state: OrchestratorState
    ) -> OrchestratorState:
        """Process with listing specialist agent"""

        # TODO: Implement when ListingAgent is created
        result = {
            "status": "pending",
            "message": "Listing agent not yet implemented",
            "classification": state.get("classification"),
        }

        return {
            **state,
            "result": result,
        }

    async def _process_with_task_agent(
        self, state: OrchestratorState
    ) -> OrchestratorState:
        """Process with task specialist agent"""

        # TODO: Implement when TaskAgent is created
        result = {
            "status": "pending",
            "message": "Task agent not yet implemented",
            "classification": state.get("classification"),
        }

        return {
            **state,
            "result": result,
        }

    def _process_generic(self, state: OrchestratorState) -> OrchestratorState:
        """Process generic messages that don't fit other categories"""

        result = {
            "status": "processed",
            "message": "Generic message processed",
            "classification": state.get("classification"),
        }

        return {
            **state,
            "result": result,
        }


# Export the graph for LangGraph configuration
orchestrator_graph = OrchestratorAgent().graph
