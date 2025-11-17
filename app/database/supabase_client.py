"""
Supabase client management with singleton pattern.
Context7 Pattern: @lru_cache for singleton + FastAPI dependency injection
Source: /supabase/supabase-py and /fastapi/fastapi docs
"""

from supabase import create_client, Client
from functools import lru_cache
from app.config.settings import get_settings


@lru_cache()
def get_supabase() -> Client:
    """
    Singleton Supabase client instance.

    Context7 Pattern:
    - Use @lru_cache() to ensure only one client is created
    - Initialize with service key for server-side operations

    Source: /supabase/supabase-py docs
    Example: create_client(url, key)

    Returns:
        Client: Supabase client instance
    """
    settings = get_settings()
    return create_client(
        supabase_url=settings.SUPABASE_URL, supabase_key=settings.supabase_service_key
    )


async def get_db() -> Client:
    """
    FastAPI dependency for injecting Supabase client.

    Context7 Pattern: Dependency injection with Depends()
    Source: /fastapi/fastapi docs - "Dependencies"

    Usage:
        @router.get("/items")
        async def get_items(db: Client = Depends(get_db)):
            response = await db.table('items').select('*').execute()
            return response.data

    Returns:
        Client: Supabase client instance
    """
    return get_supabase()
