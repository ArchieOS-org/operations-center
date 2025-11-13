"""
Agent Registry - Central hub for all intelligent agents

This module provides discovery and management of all agents in the system.
Each agent is a specialist with a single, well-defined purpose.
"""

from typing import Dict, Type, Optional
from abc import ABC, abstractmethod
from .classifier import MessageClassifier


class BaseAgent(ABC):
    """Base class for all agents"""

    @abstractmethod
    async def process(self, input_data: dict) -> dict:
        """Process input and return result"""
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        """Agent name for identification"""
        pass

    @property
    @abstractmethod
    def description(self) -> str:
        """What this agent does"""
        pass

# Agent Registry - Single source of truth for all agents
AGENT_REGISTRY: Dict[str, Type[BaseAgent]] = {
    "classifier": MessageClassifier,
    # "orchestrator": OrchestratorAgent,  # TODO: Create
    # "realtor": RealtorAgent,            # TODO: Create
    # "listing": ListingAgent,            # TODO: Create
    # "task": TaskAgent,                  # TODO: Create
    # "notification": NotificationAgent,  # TODO: Create
}


def get_agent(name: str) -> Optional[BaseAgent]:
    """
    Get an agent instance by name.

    Args:
        name: The agent identifier

    Returns:
        Agent instance or None if not found
    """
    agent_class = AGENT_REGISTRY.get(name)
    if agent_class:
        return agent_class()
    return None


def list_agents() -> Dict[str, str]:
    """
    List all available agents with their descriptions.

    Returns:
        Dictionary of agent names to descriptions
    """
    agents = {}
    for name, agent_class in AGENT_REGISTRY.items():
        instance = agent_class()
        agents[name] = instance.description
    return agents


__all__ = [
    "BaseAgent",
    "MessageClassifier",
    "AGENT_REGISTRY",
    "get_agent",
    "list_agents",
]