import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_login_and_me(client: AsyncClient) -> None:
    # Register
    resp = await client.post(
        "/api/auth/register",
        json={"email": "user@example.com", "password": "Password123"},
    )
    assert resp.status_code == 200
    token = resp.json()["access_token"]

    headers = {"Authorization": f"Bearer {token}"}

    # /me
    resp_me = await client.get("/api/auth/me", headers=headers)
    assert resp_me.status_code == 200
    data = resp_me.json()
    assert data["email"] == "user@example.com"
    assert data["timezone"] == "UTC"

    # Update timezone
    resp_tz = await client.patch(
        "/api/auth/me",
        headers=headers,
        json={"timezone": "Asia/Kolkata"},
    )
    assert resp_tz.status_code == 200
    assert resp_tz.json()["timezone"] == "Asia/Kolkata"

