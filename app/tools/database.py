"""
Database Tools - Supabase operations for agents

These tools allow agents to read from and write to the database.
All CRUD operations go through these tools.
"""

from typing import Dict, Any, Optional
from langchain.tools import tool
from database.supabase_client import get_supabase
import logging

logger = logging.getLogger(__name__)


@tool
async def store_classification(
    message_id: str,
    classification: Dict[str, Any],
    source: str = "slack"
) -> Dict[str, Any]:
    """
    Store a message classification result in the database.

    Args:
        message_id: Unique identifier for the message
        classification: Classification result from classifier agent
        source: Message source (slack, sms, etc.)

    Returns:
        Database operation result
    """
    try:
        client = get_supabase()

        # Determine the table based on source
        table_name = f"{source}_messages"

        # Update the message with classification
        result = client.table(table_name).update({
            "classification": classification,
            "processing_status": "classified",
            "classified_at": "now()"
        }).eq("id", message_id).execute()

        logger.info(f"Stored classification for {message_id} in {table_name}")
        return {"status": "success", "data": result.data}

    except Exception as e:
        logger.error(f"Failed to store classification: {str(e)}")
        return {"status": "error", "message": str(e)}


@tool
@register_tool("create_task")
async def create_task(
    title: str,
    description: str,
    realtor_id: Optional[str] = None,
    listing_id: Optional[str] = None,
    task_type: str = "general",
    priority: str = "medium"
) -> Dict[str, Any]:
    """
    Create a new task in the database.

    Args:
        title: Task title
        description: Detailed task description
        realtor_id: Optional realtor assignment
        listing_id: Optional listing association
        task_type: Type of task (general, listing, stray)
        priority: Task priority (low, medium, high, urgent)

    Returns:
        Created task data
    """
    try:
        client = get_supabase()

        # Determine which table based on task type
        if listing_id:
            table_name = "activities"
            task_data = {
                "title": title,
                "description": description,
                "listing_id": listing_id,
                "realtor_id": realtor_id,
                "priority": priority,
                "status": "pending"
            }
        elif task_type == "stray":
            table_name = "agent_tasks"
            task_data = {
                "title": title,
                "description": description,
                "realtor_id": realtor_id,
                "priority": priority,
                "status": "pending"
            }
        else:
            table_name = "agent_tasks"
            task_data = {
                "title": title,
                "description": description,
                "assigned_to": realtor_id,
                "priority": priority,
                "status": "pending"
            }

        result = client.table(table_name).insert(task_data).execute()

        logger.info(f"Created task in {table_name}: {title}")
        return {"status": "success", "task": result.data[0]}

    except Exception as e:
        logger.error(f"Failed to create task: {str(e)}")
        return {"status": "error", "message": str(e)}


@tool
@register_tool("find_realtor")
async def find_realtor(
    name: Optional[str] = None,
    email: Optional[str] = None,
    phone: Optional[str] = None
) -> Dict[str, Any]:
    """
    Find a realtor by name, email, or phone.

    Args:
        name: Realtor name (partial match supported)
        email: Realtor email
        phone: Realtor phone number

    Returns:
        Matching realtor data
    """
    try:
        client = get_supabase()
        query = client.table("realtors").select("*")

        if email:
            query = query.eq("email", email)
        elif phone:
            query = query.eq("phone", phone)
        elif name:
            query = query.ilike("name", f"%{name}%")
        else:
            return {"status": "error", "message": "Must provide search criteria"}

        result = query.execute()

        if result.data:
            logger.info(f"Found {len(result.data)} realtor(s)")
            return {"status": "success", "realtors": result.data}
        else:
            return {"status": "not_found", "message": "No matching realtors"}

    except Exception as e:
        logger.error(f"Failed to find realtor: {str(e)}")
        return {"status": "error", "message": str(e)}


@tool
@register_tool("update_listing")
async def update_listing(
    listing_id: str,
    updates: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Update a listing with new information.

    Args:
        listing_id: Listing identifier
        updates: Dictionary of fields to update

    Returns:
        Updated listing data
    """
    try:
        client = get_supabase()

        # Remove any fields that shouldn't be updated
        protected_fields = ["id", "created_at", "deleted_at"]
        for field in protected_fields:
            updates.pop(field, None)

        # Add updated timestamp
        updates["updated_at"] = "now()"

        result = client.table("listings").update(updates).eq("id", listing_id).execute()

        if result.data:
            logger.info(f"Updated listing {listing_id}")
            return {"status": "success", "listing": result.data[0]}
        else:
            return {"status": "not_found", "message": "Listing not found"}

    except Exception as e:
        logger.error(f"Failed to update listing: {str(e)}")
        return {"status": "error", "message": str(e)}


@tool
@register_tool("add_task_note")
async def add_task_note(
    task_id: str,
    note: str,
    author: str = "system"
) -> Dict[str, Any]:
    """
    Add a note to a task.

    Args:
        task_id: Task identifier
        note: Note content
        author: Note author (default: system)

    Returns:
        Created note data
    """
    try:
        client = get_supabase()

        note_data = {
            "task_id": task_id,
            "note": note,
            "created_by": author
        }

        result = client.table("task_notes").insert(note_data).execute()

        if result.data:
            logger.info(f"Added note to task {task_id}")
            return {"status": "success", "note": result.data[0]}
        else:
            return {"status": "error", "message": "Failed to add note"}

    except Exception as e:
        logger.error(f"Failed to add task note: {str(e)}")
        return {"status": "error", "message": str(e)}


# Export all tools for agent use
__all__ = [
    "store_classification",
    "create_task",
    "find_realtor",
    "update_listing",
    "add_task_note",
]