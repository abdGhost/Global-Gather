"""
GlobalEvents API entrypoint.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, engine
from app.routers import auth, events, rsvps, chat

app = FastAPI(title="GlobalEvents API", version="0.1.0")


@app.on_event("startup")
async def on_startup() -> None:
  """
  Ensure all database tables exist on startup.

  This is especially helpful on managed platforms like Render where we
  can't easily run Alembic migrations as a separate job on the free tier.
  For a brand‑new database this will create the same schema defined by
  SQLAlchemy models.
  """
  async with engine.begin() as conn:
    await conn.run_sync(Base.metadata.create_all)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(events.router)
app.include_router(rsvps.router)
app.include_router(chat.router)
