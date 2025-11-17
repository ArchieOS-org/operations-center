"""
Entity Creation from Classification Results

Transforms ClassificationV1 objects into database entities (listings, tasks).
Following LangGraph patterns and Supabase best practices from Context7.

Context7 References:
- Supabase Python: /supabase/supabase-py (insert, update, select patterns)
- LangChain: Pydantic validation, structured output
- LangGraph: Workflow node patterns
"""

from typing import Dict, Any, Optional
from datetime import datetime
import logging
from uuid import uuid4

from database.supabase_client import get_supabase
from schemas.classification import ClassificationV1, MessageType, TaskKey, GroupKey

logger = logging.getLogger(__name__)


# ============================================================================
# ACTIVITIES TEMPLATES - Auto-created for each listing type
# ============================================================================

LISTING_ACTIVITIES = {
    # Sale Listings
    GroupKey.SALE_LISTING: [
        {"name": "Take listing photos", "priority": 100, "category": "MARKETING", "visibility": "BOTH"},
        {"name": "Create MLS listing", "priority": 90, "category": "ADMIN", "visibility": "BOTH"},
        {"name": "Schedule open house", "priority": 80, "category": "MARKETING", "visibility": "BOTH"},
        {"name": "Order yard sign", "priority": 70, "category": "MARKETING", "visibility": "MARKETING"},
        {"name": "Draft listing description", "priority": 60, "category": "MARKETING", "visibility": "MARKETING"},
    ],

    # Lease Listings
    GroupKey.LEASE_LISTING: [
        {"name": "Schedule property showings", "priority": 100, "category": "ADMIN", "visibility": "BOTH"},
        {"name": "Prepare lease agreement", "priority": 90, "category": "ADMIN", "visibility": "AGENT"},
        {"name": "Run background checks", "priority": 80, "category": "ADMIN", "visibility": "AGENT"},
        {"name": "Take listing photos", "priority": 70, "category": "MARKETING", "visibility": "BOTH"},
    ],

    # Sale + Lease Listings
    GroupKey.SALE_LEASE_LISTING: [
        {"name": "Take listing photos", "priority": 100, "category": "MARKETING", "visibility": "BOTH"},
        {"name": "Create MLS listing (sale)", "priority": 90, "category": "ADMIN", "visibility": "BOTH"},
        {"name": "Create rental listing", "priority": 85, "category": "ADMIN", "visibility": "BOTH"},
        {"name": "Draft dual listing description", "priority": 80, "category": "MARKETING", "visibility": "MARKETING"},
    ],

    # Relist Listings
    GroupKey.RELIST_LISTING: [
        {"name": "Update listing photos", "priority": 100, "category": "MARKETING", "visibility": "BOTH"},
        {"name": "Refresh MLS listing", "priority": 90, "category": "ADMIN", "visibility": "BOTH"},
        {"name": "Review pricing strategy", "priority": 80, "category": "ADMIN", "visibility": "AGENT"},
    ],

    # Marketing Agenda Template
    GroupKey.MARKETING_AGENDA_TEMPLATE: [
        {"name": "Create marketing materials", "priority": 100, "category": "MARKETING", "visibility": "MARKETING"},
        {"name": "Schedule social media posts", "priority": 90, "category": "MARKETING", "visibility": "MARKETING"},
        {"name": "Design property flyer", "priority": 80, "category": "MARKETING", "visibility": "MARKETING"},
    ],

    # Default fallback for other types
    "DEFAULT": [
        {"name": "Review listing details", "priority": 100, "category": "ADMIN", "visibility": "BOTH"},
        {"name": "Schedule initial showing", "priority": 90, "category": "ADMIN", "visibility": "BOTH"},
    ]
}


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

async def resolve_realtor(assignee_hint: Optional[str]) -> Optional[str]:
    """
    Resolve assignee hint to realtor_id using fuzzy matching.

    Lookup strategy:
    1. Exact match on name
    2. Partial match on name (case-insensitive)
    3. Match on email (if @ detected)
    4. Match on phone (if phone format detected)

    Args:
        assignee_hint: Name, email, or phone from classification

    Returns:
        realtor_id (UUID string) or None if not found

    Context7 Pattern: Supabase select with ilike for fuzzy matching
    """
    if not assignee_hint:
        return None

    try:
        client = get_supabase()

        # If looks like email, try exact email match
        if "@" in assignee_hint:
            result = client.table("realtors").select("realtor_id").eq("email", assignee_hint).execute()
            if result.data and len(result.data) > 0:
                logger.info(f"Resolved realtor by email: {assignee_hint}")
                return result.data[0]["realtor_id"]

        # If looks like phone, try phone match (remove non-digits)
        if any(char.isdigit() for char in assignee_hint):
            phone_digits = ''.join(filter(str.isdigit, assignee_hint))
            if len(phone_digits) >= 10:
                result = client.table("realtors").select("realtor_id").ilike("phone", f"%{phone_digits[-10:]}%").execute()
                if result.data and len(result.data) > 0:
                    logger.info(f"Resolved realtor by phone: {phone_digits[-10:]}")
                    return result.data[0]["realtor_id"]

        # Try exact name match
        result = client.table("realtors").select("realtor_id").eq("name", assignee_hint).execute()
        if result.data and len(result.data) > 0:
            logger.info(f"Resolved realtor by exact name: {assignee_hint}")
            return result.data[0]["realtor_id"]

        # Try partial name match (case-insensitive)
        result = client.table("realtors").select("realtor_id").ilike("name", f"%{assignee_hint}%").execute()
        if result.data and len(result.data) > 0:
            logger.info(f"Resolved realtor by partial name: {assignee_hint}")
            return result.data[0]["realtor_id"]

        logger.warning(f"Could not resolve realtor for hint: {assignee_hint}")
        return None

    except Exception as e:
        logger.error(f"Error resolving realtor: {str(e)}")
        return None


def map_task_key_to_category(task_key: Optional[TaskKey]) -> str:
    """
    Map ClassificationV1 task_key enum to activities.task_category.

    Mapping:
    - SALE_ACTIVE_TASKS → MARKETING
    - LEASE_ACTIVE_TASKS → MARKETING
    - GENERAL_ADMIN → ADMIN
    - PHOTO_VIDEO → PHOTO
    - Default → ADMIN

    Args:
        task_key: TaskKey enum from classification

    Returns:
        task_category string for database
    """
    if not task_key:
        return "ADMIN"

    mapping = {
        TaskKey.SALE_ACTIVE_TASKS: "MARKETING",
        TaskKey.LEASE_ACTIVE_TASKS: "MARKETING",
        TaskKey.GENERAL_ADMIN: "ADMIN",
        TaskKey.PHOTO_VIDEO: "PHOTO",
    }

    return mapping.get(task_key, "ADMIN")


# ============================================================================
# ENTITY CREATION FUNCTIONS
# ============================================================================

async def create_listing_record(
    classification: ClassificationV1,
    realtor_id: Optional[str],
    message_text: str
) -> Optional[str]:
    """
    Create a listing record from GROUP classification.

    Context7 Pattern: Supabase insert with .execute()
    Source: /supabase/supabase-py insert examples

    Args:
        classification: ClassificationV1 object
        realtor_id: Resolved realtor UUID
        message_text: Original message for reference

    Returns:
        listing_id (UUID string) or None on error
    """
    try:
        client = get_supabase()

        # Build listing data
        listing_data = {
            "listing_id": str(uuid4()),
            "address_string": classification.listing.address if classification.listing else "Unknown Address",
            "type": classification.listing.type.value if classification.listing and classification.listing.type else None,
            "status": "new",
            "assignee": realtor_id,
            "agent_id": realtor_id,
            "due_date": classification.due_date,
            "created_at": datetime.utcnow().isoformat(),
        }

        result = client.table("listings").insert(listing_data).execute()

        if result.data and len(result.data) > 0:
            listing_id = result.data[0]["listing_id"]
            logger.info(f"Created listing: {listing_id} at {listing_data['address_string']}")
            return listing_id
        else:
            logger.error("Failed to create listing - no data returned")
            return None

    except Exception as e:
        logger.error(f"Error creating listing: {str(e)}")
        return None


async def create_activity_record(
    listing_id: str,
    realtor_id: Optional[str],
    name: str,
    priority: int,
    task_category: str,
    visibility_group: str
) -> Optional[str]:
    """
    Create an activity (listing task) record.

    CRITICAL: Column names MUST match database EXACTLY (snake_case).
    Context7 Pattern: Supabase insert with .execute()

    Args:
        listing_id: Parent listing UUID
        realtor_id: Assigned realtor UUID (nullable)
        name: Activity name
        priority: Priority value (0-100+, higher = more urgent)
        task_category: ADMIN | MARKETING | NULL
        visibility_group: BOTH | AGENT | MARKETING

    Returns:
        activity task_id (UUID string) or None on error
    """
    try:
        client = get_supabase()

        activity_data = {
            "task_id": str(uuid4()),               # PRIMARY KEY
            "listing_id": listing_id,              # FK to listings
            "realtor_id": realtor_id,              # FK to realtors (nullable)
            "name": name,                          # NOT NULL
            "description": None,                   # Optional
            "task_category": task_category,        # ADMIN | MARKETING | NULL
            "status": "OPEN",                      # Initial status
            "priority": priority,                  # 0-100+
            "visibility_group": visibility_group,  # BOTH | AGENT | MARKETING
            "assigned_staff_id": None,             # Unassigned initially
            "due_date": None,
            "claimed_at": None,
            "completed_at": None,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        result = client.table("activities").insert(activity_data).execute()

        if result.data and len(result.data) > 0:
            activity_id = result.data[0]["task_id"]
            logger.info(f"Created activity: {activity_id} - {name}")
            return activity_id
        else:
            logger.error(f"Failed to create activity '{name}' - no data returned")
            return None

    except Exception as e:
        logger.error(f"Error creating activity '{name}': {str(e)}")
        return None


async def create_listing_with_activities(
    classification: ClassificationV1,
    realtor_id: Optional[str],
    message_text: str
) -> Optional[str]:
    """
    Create listing record + auto-attach activities based on group_key.

    This replaces create_listing_record for GROUP message types,
    adding automatic activity creation based on listing type.

    Args:
        classification: ClassificationV1 object
        realtor_id: Resolved realtor UUID
        message_text: Original message for reference

    Returns:
        listing_id (UUID string) or None on error
    """
    # First, create the listing
    listing_id = await create_listing_record(
        classification=classification,
        realtor_id=realtor_id,
        message_text=message_text
    )

    if not listing_id:
        logger.error("Failed to create listing, skipping activities")
        return None

    # Then, auto-create activities based on group_key
    group_key = classification.group_key

    if not group_key:
        logger.warning("No group_key in classification, skipping activities")
        return listing_id

    # Get activities template for this listing type
    activities_template = LISTING_ACTIVITIES.get(group_key, LISTING_ACTIVITIES["DEFAULT"])

    logger.info(
        f"Creating {len(activities_template)} activities for "
        f"listing {listing_id} (type: {group_key.value})"
    )

    # Create each activity
    created_count = 0
    for activity in activities_template:
        activity_id = await create_activity_record(
            listing_id=listing_id,
            realtor_id=realtor_id,
            name=activity["name"],
            priority=activity["priority"],
            task_category=activity["category"],
            visibility_group=activity["visibility"]
        )

        if activity_id:
            created_count += 1

    logger.info(
        f"Successfully created {created_count}/{len(activities_template)} "
        f"activities for listing {listing_id}"
    )

    return listing_id


async def create_agent_task_record(
    classification: ClassificationV1,
    realtor_id: Optional[str],
    message_text: str,
    is_info_request: bool = False
) -> Optional[str]:
    """
    Create an agent_task record from STRAY or INFO_REQUEST classification.

    Context7 Pattern: Supabase insert with .execute()
    Source: /supabase/supabase-py insert examples

    Args:
        classification: ClassificationV1 object
        realtor_id: Resolved realtor UUID
        message_text: Original message for description
        is_info_request: True if message_type is INFO_REQUEST

    Returns:
        task_id (UUID string) or None on error
    """
    try:
        client = get_supabase()

        # Determine status based on message type
        status = "NEEDS_INFO" if is_info_request else "OPEN"

        # Build task data
        task_data = {
            "task_id": str(uuid4()),
            "realtor_id": realtor_id,
            "task_key": classification.task_key.value if classification.task_key else "GENERAL_ADMIN",
            "name": classification.task_title or "Untitled Task",
            "description": message_text,
            "status": status,
            "priority": 5,  # Default medium priority
            "due_date": classification.due_date,
            "notes": classification.explanations if classification.explanations else [],
            "created_at": datetime.utcnow().isoformat(),
        }

        result = client.table("agent_tasks").insert(task_data).execute()

        if result.data and len(result.data) > 0:
            task_id = result.data[0]["task_id"]
            logger.info(f"Created agent task: {task_id} - {task_data['name']}")
            return task_id
        else:
            logger.error("Failed to create agent task - no data returned")
            return None

    except Exception as e:
        logger.error(f"Error creating agent task: {str(e)}")
        return None


async def update_slack_message_with_entity(
    message_id: str,
    listing_id: Optional[str] = None,
    task_id: Optional[str] = None,
    task_type: Optional[str] = None,
    processing_status: str = "processed"
) -> bool:
    """
    Update slack_messages table with created entity IDs.

    Context7 Pattern: Supabase update with .eq() filter
    Source: /supabase/supabase-py update examples

    Args:
        message_id: ID of slack_messages record
        listing_id: Created listing UUID
        task_id: Created task UUID
        task_type: 'listing' or 'stray_task'
        processing_status: 'processed', 'skipped', or 'failed'

    Returns:
        True if update succeeded
    """
    try:
        client = get_supabase()

        update_data = {
            "processing_status": processing_status,
            "processed_at": datetime.utcnow().isoformat(),
        }

        if listing_id:
            update_data["created_listing_id"] = listing_id
            update_data["created_task_type"] = "listing"

        if task_id:
            update_data["created_task_id"] = task_id
            update_data["created_task_type"] = task_type or "agent_task"

        result = client.table("slack_messages").update(update_data).eq("id", message_id).execute()

        if result.data and len(result.data) > 0:
            logger.info(f"Updated slack_messages {message_id} with entity links")
            return True
        else:
            logger.warning(f"No slack_messages record found for ID: {message_id}")
            return False

    except Exception as e:
        logger.error(f"Error updating slack_messages: {str(e)}")
        return False


# ============================================================================
# MAIN ENTITY CREATION LOGIC
# ============================================================================

async def create_entities_from_classification(
    classification: ClassificationV1,
    message_id: str,
    message_text: str
) -> Dict[str, Any]:
    """
    Main entity creation logic - routes by message_type.

    Decision tree:
    - GROUP → Create listing
    - STRAY → Create stray task
    - INFO_REQUEST → Create stray task with NEEDS_INFO status
    - IGNORE → Skip entity creation, mark as skipped

    Context7 Patterns:
    - Pydantic validation (ClassificationV1 already validated)
    - Supabase insert/update operations
    - Error handling with try/except

    Args:
        classification: Validated ClassificationV1 object
        message_id: ID of slack_messages record to update
        message_text: Original Slack message text

    Returns:
        Dict with status, entity_type, entity_id
    """
    message_type = classification.message_type

    logger.info(f"Creating entities for message_type: {message_type.value}")

    try:
        # IGNORE messages - skip entity creation
        if message_type == MessageType.IGNORE:
            await update_slack_message_with_entity(
                message_id=message_id,
                processing_status="skipped"
            )
            return {
                "status": "skipped",
                "message_type": message_type.value,
                "reason": "Message type is IGNORE"
            }

        # Resolve realtor for all non-IGNORE messages
        realtor_id = await resolve_realtor(classification.assignee_hint)

        # GROUP messages → Create listing + activities
        if message_type == MessageType.GROUP:
            listing_id = await create_listing_with_activities(
                classification=classification,
                realtor_id=realtor_id,
                message_text=message_text
            )

            if listing_id:
                await update_slack_message_with_entity(
                    message_id=message_id,
                    listing_id=listing_id,
                    processing_status="processed"
                )
                return {
                    "status": "success",
                    "message_type": message_type.value,
                    "entity_type": "listing",
                    "entity_id": listing_id,
                    "realtor_id": realtor_id
                }
            else:
                await update_slack_message_with_entity(
                    message_id=message_id,
                    processing_status="failed"
                )
                return {
                    "status": "error",
                    "message_type": message_type.value,
                    "reason": "Failed to create listing"
                }

        # STRAY or INFO_REQUEST messages → Create agent task
        elif message_type in [MessageType.STRAY, MessageType.INFO_REQUEST]:
            is_info_request = (message_type == MessageType.INFO_REQUEST)

            task_id = await create_agent_task_record(
                classification=classification,
                realtor_id=realtor_id,
                message_text=message_text,
                is_info_request=is_info_request
            )

            if task_id:
                await update_slack_message_with_entity(
                    message_id=message_id,
                    task_id=task_id,
                    task_type="agent_task",
                    processing_status="processed"
                )
                return {
                    "status": "success",
                    "message_type": message_type.value,
                    "entity_type": "agent_task",
                    "entity_id": task_id,
                    "realtor_id": realtor_id
                }
            else:
                await update_slack_message_with_entity(
                    message_id=message_id,
                    processing_status="failed"
                )
                return {
                    "status": "error",
                    "message_type": message_type.value,
                    "reason": "Failed to create agent task"
                }

        else:
            # Unknown message type
            logger.warning(f"Unknown message_type: {message_type}")
            await update_slack_message_with_entity(
                message_id=message_id,
                processing_status="failed"
            )
            return {
                "status": "error",
                "message_type": message_type.value if message_type else "UNKNOWN",
                "reason": "Unknown message type"
            }

    except Exception as e:
        logger.error(f"Entity creation failed: {str(e)}")
        await update_slack_message_with_entity(
            message_id=message_id,
            processing_status="failed"
        )
        return {
            "status": "error",
            "reason": str(e)
        }
