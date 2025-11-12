"""
Tools Registry - Reusable capabilities for agents

Tools are the building blocks that agents use to interact with the world.
Each tool should do one thing well and be composable with others.
"""

from typing import Dict, Callable, List

# Tool Registry - All available tools
TOOL_REGISTRY: Dict[str, Callable] = {}


def register_tool(name: str, func: Callable):
    """Register a tool for use by agents"""
    TOOL_REGISTRY[name] = func
    return func


def get_tool(name: str) -> Callable:
    """Get a tool by name"""
    return TOOL_REGISTRY.get(name)


def list_tools() -> List[str]:
    """List all available tool names"""
    return list(TOOL_REGISTRY.keys())


# Import and register all tools
# from . import database
# from . import notifications
# from . import search
# from . import memory

__all__ = [
    "TOOL_REGISTRY",
    "register_tool",
    "get_tool",
    "list_tools",
]