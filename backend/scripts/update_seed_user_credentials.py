from __future__ import annotations

import asyncio
import os
import sys

from sqlalchemy import select

ROOT_DIR = os.path.dirname(os.path.dirname(__file__))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from app.core.security import hash_password
from app.database import async_session_maker
from app.models.user import User

OLD_EMAIL = "real.user.silchar@globalgather.app"
NEW_EMAIL = "ghost@gmail.com"
NEW_PASSWORD = "ghost123"


async def main() -> None:
    async with async_session_maker() as session:
        old_result = await session.execute(select(User).where(User.email == OLD_EMAIL))
        old_user = old_result.scalar_one_or_none()
        target_result = await session.execute(select(User).where(User.email == NEW_EMAIL))
        target_user = target_result.scalar_one_or_none()

        if old_user and target_user and old_user.id != target_user.id:
            # Free NEW_EMAIL first; otherwise both rows briefly use it and Postgres
            # raises unique constraint on email depending on UPDATE order.
            target_user.email = f"archived+{target_user.id.hex[:8]}@globalgather.app"
            await session.flush()
            old_user.email = NEW_EMAIL
            old_user.hashed_password = hash_password(NEW_PASSWORD)
            print("Renamed seeded user to target email and archived existing target account.")
        elif old_user:
            old_user.email = NEW_EMAIL
            old_user.hashed_password = hash_password(NEW_PASSWORD)
            print("Renamed seeded user and updated password.")
        elif target_user:
            target_user.hashed_password = hash_password(NEW_PASSWORD)
            print("Updated existing target user password.")
        else:
            user = User(
                email=NEW_EMAIL,
                hashed_password=hash_password(NEW_PASSWORD),
                is_active=True,
                is_verified=True,
                timezone="Asia/Kolkata",
            )
            session.add(user)
            print("Created target user with requested credentials.")

        await session.commit()


if __name__ == "__main__":
    asyncio.run(main())
