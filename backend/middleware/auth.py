"""
Authentication middleware using FastAPI dependency injection.
Context7 Pattern: Depends() for reusable auth logic
Source: /fastapi/fastapi docs - "Dependencies" and "Security"
"""
from fastapi import Depends, HTTPException, Header, Cookie
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from typing import Annotated, Optional
from backend.models.user import User
from backend.config import get_settings

# Context7 Pattern: HTTPBearer for Authorization header
security = HTTPBearer(auto_error=False)


async def get_current_user(
    authorization: Annotated[
        Optional[HTTPAuthorizationCredentials], 
        Depends(security)
    ] = None,
    x_debug_user: Annotated[Optional[str], Header()] = None,
    ops_session: Annotated[Optional[str], Cookie()] = None
) -> User:
    """
    FastAPI dependency to extract and validate current user.

    Context7 Pattern: Multiple authentication methods via Depends()
    Source: /fastapi/fastapi - "Custom Header Dependency"

    Supports:
    1. Bearer token (Authorization header)
    2. Session cookie (ops_session)
    3. Debug header (X-Debug-User, local dev only)

    Args:
        authorization: Bearer token from Authorization header
        x_debug_user: Debug user ID (local development only)
        ops_session: Session cookie with JWT

    Returns:
        User: Authenticated user object

    Raises:
        HTTPException: 401 if authentication fails
    """
    settings = get_settings()

    # Debug mode (local development)
    if settings.ENABLE_DEBUG_AUTH and x_debug_user:
        return User(
            user_id=x_debug_user,
            email=f"{x_debug_user}@debug.local",
            name=f"Debug User {x_debug_user}",
            provider="debug",
            roles=[],
            groups=[]
        )

    # Extract token from Bearer or Cookie
    token = None
    if authorization:
        token = authorization.credentials
    elif ops_session:
        token = ops_session

    if not token:
        raise HTTPException(
            status_code=401,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Validate JWT
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM]
        )

        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")

        return User(
            user_id=user_id,
            email=payload.get("email"),
            name=payload.get("name"),
            tenant_id=payload.get("tenant_id"),
            provider=payload.get("provider", "cognito"),
            roles=payload.get("roles", []),
            groups=payload.get("groups", [])
        )

    except JWTError as e:
        raise HTTPException(
            status_code=401,
            detail=f"Could not validate credentials: {str(e)}"
        )
