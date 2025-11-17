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
    SUPABASE_SERVICE_KEY: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None

    # Authentication
    JWT_SECRET: str | None = None
    SUPABASE_JWT_SECRET: str | None = None

    @property
    def supabase_service_key(self) -> str:
        """Return service key from either env var name"""
        return self.SUPABASE_SERVICE_KEY or self.SUPABASE_SERVICE_ROLE_KEY

    @property
    def jwt_secret(self) -> str:
        """Return JWT secret from either env var name"""
        return self.JWT_SECRET or self.SUPABASE_JWT_SECRET
    JWT_ALGORITHM: str = "HS256"
    ENABLE_DEBUG_AUTH: bool = False

    # OpenAI (for existing classifier)
    OPENAI_API_KEY: str

    # Slack (for existing webhook)
    SLACK_SIGNING_SECRET: str
    SLACK_BYPASS_VERIFY: bool = False
    SLACK_BOT_TOKEN: str  # For posting acknowledgments via WebClient

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
