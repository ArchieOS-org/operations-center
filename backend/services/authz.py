"""
Authorization helpers for role-based and ownership-based access control.
Context7 Pattern: Reusable dependency functions with sub-dependencies
Source: /fastapi/fastapi docs - "Sub-dependencies" and "Dependencies"
"""
from fastapi import HTTPException, Depends
from typing import Annotated
from backend.models.user import User
from backend.models.task import TaskDetail
from backend.middleware.auth import get_current_user


def has_role(user: User, role: str) -> bool:
    """
    Check if user has a specific role.
    
    Context7 Pattern: Simple helper function for authorization logic
    """
    return role in user.roles


def has_group(user: User, group: str) -> bool:
    """Check if user belongs to a specific group."""
    return group in user.groups


def is_admin(user: User) -> bool:
    """Check if user is an admin."""
    return has_role(user, "ADMIN_OPS") or has_role(user, "ADMIN_MARKETING")


def can_see_task(user: User, visibility_group: str) -> bool:
    """
    Check if user can see a task based on visibility group.
    
    Context7 Pattern: Business logic in reusable functions
    Source: /fastapi/fastapi - "Dependency Injection"
    
    Args:
        user: Current user
        visibility_group: Task visibility ("BOTH", "AGENT", "MARKETING")
    
    Returns:
        bool: True if user can see the task
    """
    if visibility_group == "BOTH":
        return True
    
    if visibility_group == "AGENT":
        return has_group(user, "AGENT") or is_admin(user)
    
    if visibility_group == "MARKETING":
        return has_group(user, "MARKETING") or is_admin(user)
    
    return False


def can_claim_task(user: User, task: TaskDetail) -> bool:
    """
    Check if user can claim a task.
    
    Rules:
    - Task must be OPEN
    - User must be able to see the task
    - Admins can claim any task
    """
    if task.status != "OPEN":
        return False
    
    if not can_see_task(user, task.visibility_group):
        return False
    
    return True


def can_unclaim_task(user: User, task: TaskDetail) -> bool:
    """
    Check if user can unclaim a task.
    
    Rules:
    - Task must be CLAIMED
    - Either: user is the assignee OR user is admin
    """
    if task.status != "CLAIMED":
        return False
    
    return task.assignee_id == user.user_id or is_admin(user)


def can_complete_task(user: User, task: TaskDetail) -> bool:
    """
    Check if user can complete a task.
    
    Rules:
    - Task must be CLAIMED
    - User must be the assignee (admins cannot complete others' tasks)
    """
    if task.status != "CLAIMED":
        return False
    
    return task.assignee_id == user.user_id


def can_reopen_task(user: User, task: TaskDetail) -> bool:
    """
    Check if user can reopen a completed task.
    
    Rules:
    - Task must be DONE or FAILED
    - Either: user was the assignee OR user is admin
    """
    if task.status not in ["DONE", "FAILED"]:
        return False
    
    return task.assignee_id == user.user_id or is_admin(user)


def can_delete_task(user: User, task: TaskDetail) -> bool:
    """
    Check if user can delete a task.
    
    Rules:
    - Only admins can delete tasks
    """
    return is_admin(user)


# Context7 Pattern: Dependency functions that raise HTTPException
# Source: /fastapi/fastapi - "Custom Header Dependency"

async def require_admin(
    user: Annotated[User, Depends(get_current_user)]
) -> User:
    """
    FastAPI dependency that requires admin role.
    
    Context7 Pattern: Sub-dependency with validation
    Source: /fastapi/fastapi - "Sub-dependencies"
    
    Usage:
        @router.post("/admin/action")
        async def admin_action(user: User = Depends(require_admin)):
            # Only admins can reach here
            pass
    
    Raises:
        HTTPException: 403 if user is not admin
    """
    if not is_admin(user):
        raise HTTPException(
            status_code=403,
            detail="Admin role required"
        )
    return user


async def require_role(role: str):
    """
    FastAPI dependency factory that requires specific role.
    
    Context7 Pattern: Dependency with parameters
    Source: /fastapi/fastapi - "Dependencies with parameters"
    
    Usage:
        @router.get("/ops")
        async def ops_action(user: User = Depends(require_role("ADMIN_OPS"))):
            pass
    """
    async def role_checker(user: Annotated[User, Depends(get_current_user)]) -> User:
        if not has_role(user, role):
            raise HTTPException(
                status_code=403,
                detail=f"Role '{role}' required"
            )
        return user
    
    return role_checker


async def require_group(group: str):
    """
    FastAPI dependency factory that requires specific group.
    
    Context7 Pattern: Dependency factory pattern
    """
    async def group_checker(user: Annotated[User, Depends(get_current_user)]) -> User:
        if not has_group(user, group):
            raise HTTPException(
                status_code=403,
                detail=f"Group '{group}' required"
            )
        return user
    
    return group_checker
