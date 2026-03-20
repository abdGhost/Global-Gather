"""
App settings (env-based).
"""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Default to local SQLite for development; can be overridden via .env
    # Example PostgreSQL URL for later:
    # postgresql+asyncpg://postgres:password@localhost:5432/globalevents
    database_url: str = "sqlite+aiosqlite:///./globalevents.db"
    sql_echo: bool = False
    redis_url: str = "redis://localhost:6379/0"
    secret_key: str = "change-me-in-production"
    timezone_header: str = "X-Timezone"
    # When true, if the DB has zero events on startup, run demo seed scripts (Render fresh DB).
    seed_on_empty: bool = False

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
