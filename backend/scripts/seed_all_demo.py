"""
Load all demo / real-world seed data into the database (always runs — not only when empty).

Usage from backend root:
  python scripts/seed_all_demo.py

Requires DATABASE_URL in .env (e.g. Render Postgres). Idempotent where each seed
uses title+start_utc or similar checks; safe to re-run.
"""
from __future__ import annotations

import asyncio
import logging
import os
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)
SCRIPTS_DIR = os.path.join(ROOT_DIR, "scripts")
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)


def _load_dotenv_override() -> None:
    """Force `backend/.env` into os.environ so seeds hit Render Postgres, not a stale shell DATABASE_URL (e.g. SQLite)."""
    env_path = os.path.join(ROOT_DIR, ".env")
    if not os.path.isfile(env_path):
        return
    with open(env_path, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key:
                os.environ[key] = value


_load_dotenv_override()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def main() -> None:
    from app.database import Base, engine

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    import seed_event_chats
    import seed_nearby_events
    import seed_profile_real_user
    import seed_real_events
    import seed_silchar_nearby_events

    logger.info("Running seed_real_events…")
    await seed_real_events.seed_real_events()
    logger.info("Running seed_nearby_events…")
    await seed_nearby_events.seed_nearby_events()
    logger.info("Running seed_silchar_nearby_events…")
    await seed_silchar_nearby_events.seed()
    logger.info("Running seed_event_chats…")
    await seed_event_chats.seed_event_chats()
    logger.info("Running seed_profile_real_user…")
    await seed_profile_real_user.seed()

    import update_seed_user_credentials

    logger.info("Running update_seed_user_credentials…")
    await update_seed_user_credentials.main()

    logger.info("All demo seeds finished (ghost@gmail.com / ghost123 when applicable).")


if __name__ == "__main__":
    asyncio.run(main())
