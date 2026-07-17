# FIXES

## Bug 1
- File: `api/main.py`
- Line number: 9-25, 34-47
- Problem: Redis connection and front-end integration were hardcoded for local development only. The API also returned a generic 200 response for missing jobs and had no runtime port configuration.
- Solution: Added environment variables for `REDIS_URL`, `REDIS_HOST`, `REDIS_PORT`, `CORS_ORIGINS`, and `PORT`; enabled CORS middleware; raised `HTTPException(status_code=404)` for missing jobs; decoded Redis byte responses; added a `__main__` startup block for `uvicorn`.

## Bug 2
- File: `frontend/app.js`
- Line number: 6-7
- Problem: The frontend was hardcoded to use `http://localhost:8000` and port `3000`, making it inflexible for production.
- Solution: Replaced hardcoded values with `process.env.API_URL` and `process.env.PORT`.

## Bug 3
- File: `worker/worker.py`
- Line number: 7-15, 18-30
- Problem: The worker used a hardcoded Redis host/port and had no environment-based configuration or graceful shutdown handling.
- Solution: Added `REDIS_URL`, `REDIS_HOST`, `REDIS_PORT`, and `WORKER_DELAY` environment variables; configured the Redis client from env values; added signal handlers for `SIGTERM` and `SIGINT`.

## Bug 4
- File: `README.md`
- Line number: 3-41
- Problem: The project had no documented environment variables or run instructions for the updated production-ready configuration.
- Solution: Added a `Environment variables` section documenting API, frontend, and worker settings, plus `Run` instructions for each component.
