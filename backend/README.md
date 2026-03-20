# Global Gather API

## Render: empty database after rebuild

A **new** or **wiped** Postgres has no rows. The API only creates **tables** on startup, not demo data.

### Option A — Automatic demo data (recommended)

In the Render **Web Service → Environment**, add:

| Key | Value |
|-----|--------|
| `SEED_ON_EMPTY` | `true` |

On each deploy, if the `events` table has **zero** rows, the app will load demo events, nearby events, chats, and the `ghost@gmail.com` test user (`ghost123`) in one pass.

Leave `SEED_ON_EMPTY` unset or `false` in production if you do not want this behavior.

### Option B — Manual (local shell with production `DATABASE_URL`)

From the `backend` folder:

```bash
set DATABASE_URL=postgresql+asyncpg://...
python -c "import asyncio; from app.auto_seed import seed_database_if_empty; asyncio.run(seed_database_if_empty())"
```

Or run individual scripts under `scripts/`.

### Required env vars on Render

- `DATABASE_URL` — `postgresql+asyncpg://...` (from Render Postgres)
- `SECRET_KEY` — strong random string for JWT
