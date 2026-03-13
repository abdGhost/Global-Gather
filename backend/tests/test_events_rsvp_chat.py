from datetime import datetime, timedelta, timezone
from uuid import UUID

import pytest
from httpx import AsyncClient


async def _auth_header(client: AsyncClient, email: str) -> dict[str, str]:
    resp = await client.post(
        "/api/auth/register",
        json={"email": email, "password": "Password123"},
    )
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _now_utc_offset(hours: int = 0) -> datetime:
    return datetime.now(timezone.utc) + timedelta(hours=hours)


@pytest.mark.asyncio
async def test_create_event_and_trending(client: AsyncClient) -> None:
    headers = await _auth_header(client, "creator@example.com")

    start = _now_utc_offset(1)
    end = _now_utc_offset(3)

    body = {
        "title": "Test Event",
        "description": "Backend test event",
        "start_local": start.isoformat(),
        "end_local": end.isoformat(),
        "timezone": "UTC",
        "lat": 40.7128,
        "lng": -74.0060,
        "address": "New York",
        "city": "New York",
        "country_code": "US",
        "is_virtual": False,
        "category": "Meetup",
        "image_url": None,
        "max_attendees": 100,
    }

    resp = await client.post("/api/events", headers=headers, json=body)
    assert resp.status_code == 201
    event = resp.json()
    event_id = event["id"]

    # Trending should include the event
    resp_trending = await client.get("/api/events/trending")
    assert resp_trending.status_code == 200
    ids = [e["id"] for e in resp_trending.json()]
    assert event_id in ids


@pytest.mark.asyncio
async def test_rsvp_flow(client: AsyncClient) -> None:
    headers_owner = await _auth_header(client, "owner@example.com")

    start = _now_utc_offset(1)
    end = _now_utc_offset(2)
    body = {
        "title": "RSVP Event",
        "description": None,
        "start_local": start.isoformat(),
        "end_local": end.isoformat(),
        "timezone": "UTC",
        "lat": 51.5,
        "lng": -0.12,
        "address": "London",
        "city": "London",
        "country_code": "GB",
        "is_virtual": False,
        "category": "Meetup",
        "image_url": None,
        "max_attendees": 50,
    }
    resp = await client.post("/api/events", headers=headers_owner, json=body)
    assert resp.status_code == 201
    event_id = resp.json()["id"]

    headers_user = await _auth_header(client, "attendee@example.com")

    # Initial status
    resp_status = await client.get(f"/api/events/{event_id}/rsvp", headers=headers_user)
    assert resp_status.status_code == 200
    status_data = resp_status.json()
    assert status_data["count"] == 0
    assert status_data["is_going"] is False

    # RSVP
    resp_join = await client.post(
        f"/api/events/{event_id}/rsvp", headers=headers_user
    )
    assert resp_join.status_code == 201

    resp_status2 = await client.get(
        f"/api/events/{event_id}/rsvp", headers=headers_user
    )
    data2 = resp_status2.json()
    assert data2["count"] == 1
    assert data2["is_going"] is True

    # Cancel
    resp_del = await client.delete(
        f"/api/events/{event_id}/rsvp", headers=headers_user
    )
    assert resp_del.status_code == 204

    resp_status3 = await client.get(
        f"/api/events/{event_id}/rsvp", headers=headers_user
    )
    data3 = resp_status3.json()
    assert data3["is_going"] is False


@pytest.mark.asyncio
async def test_chat_http_messages(client: AsyncClient) -> None:
    headers = await _auth_header(client, "chatuser@example.com")

    start = _now_utc_offset(1)
    end = _now_utc_offset(2)
    body = {
        "title": "Chat Event",
        "description": "Chat test",
        "start_local": start.isoformat(),
        "end_local": end.isoformat(),
        "timezone": "UTC",
        "lat": 0.0,
        "lng": 0.0,
        "address": "Nowhere",
        "city": "Nowhere",
        "country_code": "US",
        "is_virtual": True,
        "category": "Online",
        "image_url": None,
        "max_attendees": 0,
    }
    resp_event = await client.post("/api/events", headers=headers, json=body)
    assert resp_event.status_code == 201
    event_id = resp_event.json()["id"]

    # Post a message
    resp_msg = await client.post(
        f"/api/events/{event_id}/chat/messages",
        headers=headers,
        json={"content": "Hello from tests"},
    )
    assert resp_msg.status_code == 201
    msg_data = resp_msg.json()
    assert msg_data["content"] == "Hello from tests"
    assert UUID(msg_data["event_id"])  # valid UUID

    # Fetch history
    resp_history = await client.get(f"/api/events/{event_id}/chat/messages")
    assert resp_history.status_code == 200
    history = resp_history.json()
    assert any(m["content"] == "Hello from tests" for m in history)

