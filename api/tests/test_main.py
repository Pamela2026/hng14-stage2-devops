from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient


def make_client():
    mock_redis = MagicMock()
    with patch("main.redis") as mock_redis_module:
        mock_redis_module.Redis.return_value = mock_redis
        mock_redis_module.Redis.from_url.return_value = mock_redis
        import importlib
        import main as m
        importlib.reload(m)
        m.r = mock_redis
        return TestClient(m.app), mock_redis


def test_create_job_returns_job_id():
    client, mock_r = make_client()
    mock_r.lpush.return_value = 1
    mock_r.hset.return_value = 1

    response = client.post("/jobs")

    assert response.status_code == 200
    data = response.json()
    assert "job_id" in data
    assert len(data["job_id"]) == 36  # UUID format


def test_get_job_returns_status():
    client, mock_r = make_client()
    mock_r.hget.return_value = b"queued"

    response = client.get("/jobs/test-job-123")

    assert response.status_code == 200
    data = response.json()
    assert data["job_id"] == "test-job-123"
    assert data["status"] == "queued"


def test_get_job_not_found():
    client, mock_r = make_client()
    mock_r.hget.return_value = None

    response = client.get("/jobs/nonexistent-job")

    assert response.status_code == 404
    assert response.json()["detail"] == "job not found"


def test_create_job_enqueues_to_redis():
    client, mock_r = make_client()
    mock_r.lpush.return_value = 1
    mock_r.hset.return_value = 1

    response = client.post("/jobs")
    job_id = response.json()["job_id"]

    mock_r.lpush.assert_called_once_with("job", job_id)
    mock_r.hset.assert_called_once_with(f"job:{job_id}", "status", "queued")


def test_get_job_decodes_bytes_status():
    client, mock_r = make_client()
    mock_r.hget.return_value = b"completed"

    response = client.get("/jobs/some-job")

    assert response.json()["status"] == "completed"
