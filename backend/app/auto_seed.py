"""
Populate an empty database with demo data (events, chats, profile user).

Used when Render gives you a fresh Postgres after rebuild. Enable with
environment variable: SEED_ON_EMPTY=true
"""
from __future__ import annotations

import logging
import sys
from pathlib import Path

from sqlalchemy import func, select

from app.database import Base, async_session_maker, engine
from app.models.event import Event

logger = logging.getLogger(__name__)


def _ensure_scripts_importable() -> None:
    backend_root = Path(__file__).resolve().parent.parent
    scripts_dir = backend_root / "scripts"
    for p in (str(backend_root), str(scripts_dir)):
        if p not in sys.path:
            sys.path.insert(0, p)


async def seed_database_if_empty() -> None:
    """Run all demo seed scripts only when there are zero events."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_maker() as session:
        n = await session.scalar(select(func.count()).select_from(Event))
        if n and n > 0:
            logger.info("auto_seed: skipped (database already has %s events)", n)
            return

    logger.info("auto_seed: empty database — running demo seeds…")
    _ensure_scripts_importable()

    import seed_event_chats
    import seed_nearby_events
    import seed_profile_real_user
    import seed_real_events
    import seed_silchar_nearby_events

    await seed_real_events.seed_real_events()
    await seed_nearby_events.seed_nearby_events()
    await seed_silchar_nearby_events.seed()
    await seed_event_chats.seed_event_chats()
    await seed_profile_real_user.seed()

    import update_seed_user_credentials

    await update_seed_user_credentials.main()

    logger.info("auto_seed: demo data load complete (includes ghost@gmail.com demo user)")
