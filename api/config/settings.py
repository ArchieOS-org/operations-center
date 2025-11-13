"""
Configuration management using Pydantic Settings.
Context7 Pattern: BaseSettings with @lru_cache singleton
Source: /pydantic/pydantic and /fastapi/fastapi docs
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    Context7 best practice: Use BaseSettings for env var validation.
    """

    # Supabase
    SUPABASE_URL: str
    SUPABASE_ANON_KEY: str
    SUPABASE_SERVICE_KEY: str

    # Authentication
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    ENABLE_DEBUG_AUTH: bool = False

    # OpenAI (for existing classifier)
    OPENAI_API_KEY: str

    # Slack (for existing webhook)
    SLACK_SIGNING_SECRET: str
    SLACK_BYPASS_VERIFY: bool = False

    # Application
    APP_NAME: str = "Operations Center API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    class Config:
        """Pydantic configuration."""
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """
    Cached settings instance.
    Context7 Pattern: @lru_cache ensures singleton behavior.
    Source: /fastapi/fastapi docs - "Settings and environment variables"
    """
    return Settings()
