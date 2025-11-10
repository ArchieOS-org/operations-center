"""
Supabase Client Module

Provides a singleton Supabase client instance for the application.
Reads credentials from environment variables.
"""

import os
from supabase import create_client, Client

_supabase_client = None


def get_supabase() -> Client:
    """
    Get or create Supabase client singleton

    Returns:
        Client: Supabase client instance

    Raises:
        ValueError: If SUPABASE_URL or SUPABASE_KEY environment variables are not set
    """
    global _supabase_client

    if _supabase_client is None:
        url = os.getenv('SUPABASE_URL')
        key = os.getenv('SUPABASE_KEY')

        if not url or not key:
            raise ValueError(
                "Missing Supabase credentials. "
                "Set SUPABASE_URL and SUPABASE_KEY environment variables."
            )

        _supabase_client = create_client(url, key)

    return _supabase_client


def test_connection():
    """Test Supabase connection"""
    try:
        supabase = get_supabase()
        result = supabase.table('classifications').select('*', count='exact').limit(0).execute()
        print(f"✅ Supabase connected! (Using service role key)")
        return True
    except Exception as e:
        print(f"❌ Supabase connection failed: {e}")
        return False


if __name__ == "__main__":
    # Test connection
    from dotenv import load_dotenv
    load_dotenv()
    test_connection()
