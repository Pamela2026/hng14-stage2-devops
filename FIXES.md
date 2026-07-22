# FIXES

---

## Fix 1

**File:** `api/main.py`
**Lines:** 9–25

**Problem:** Redis connection was hardcoded for local development. No CORS middleware. No runtime port configuration. Missing jobs returned 200 instead of 404. Redis responses were not decoded from bytes.

**Solution:** Added `REDIS_URL`, `REDIS_HOST`, `REDIS_PORT`, `CORS_ORIGINS`, and `PORT` environment variables. Added `CORSMiddleware`. Raised `HTTPException(404)` for missing jobs. Decoded Redis byte responses. Added `uvicorn` startup block in `__main__`.

---

## Fix 2

**File:** `frontend/app.js`
**Lines:** 6–7

**Problem:** `API_URL` and `PORT` were hardcoded, making the frontend unusable in any environment other than local.

**Solution:** Replaced hardcoded values with `process.env.API_URL` and `process.env.PORT`.

---

## Fix 3

**File:** `worker/worker.py`
**Lines:** 7–15

**Problem:** Redis host and port were hardcoded. No graceful shutdown on `SIGTERM`/`SIGINT`. No configurable work delay.

**Solution:** Added `REDIS_URL`, `REDIS_HOST`, `REDIS_PORT`, and `WORKER_DELAY` environment variables. Added signal handlers for graceful shutdown.

---

## Fix 4

**File:** `api/main.py`
**Lines:** 19–22

**Problem:** flake8 violations — E501 (line too long), E302/E305 (missing blank lines around functions). Variable name `origin` in list comprehension caused line length to exceed 100 characters.

**Solution:** Shortened list comprehension variable to `o`. Added two blank lines before each function definition.

---

## Fix 5

**File:** `api/Dockerfile`, `worker/Dockerfile`
**Lines:** 1

**Problem:** Base image `python:3.11-slim` contained `perl-base` with CRITICAL CVEs (CVE-2026-13221, CVE-2026-42496, CVE-2026-8376) with no fixed version available.

**Solution:** Switched base image to `python:3.11-alpine` which does not ship `perl-base`.

---

## Fix 6

**File:** `frontend/Dockerfile`
**Lines:** 1, 13

**Problem:** `node:18-alpine` is EOL (April 2025) and contained CRITICAL CVE CVE-2026-59873 in `tar@6.2.1` bundled inside npm.

**Solution:** Upgraded to `node:20.20.2-alpine3.22` (LTS). Removed npm from the final image (`rm -rf /usr/local/lib/node_modules/npm`) since it is not needed at runtime. Removed `package.json` and `package-lock.json` from the final image to prevent Trivy scanning the lockfile.

---

## Fix 7

**File:** `frontend/package.json`

**Problem:** `tar@6.2.1` was being resolved as a transitive dependency and appearing in the lockfile, causing Trivy to flag it even after npm was removed.

**Solution:** Added `"overrides": { "tar": ">=7.5.19" }` to force resolution to the patched version.

---

## Fix 8

**File:** `api/Dockerfile`, `worker/Dockerfile`
**Lines:** 9

**Problem:** Final stage used `python:3.11-alpine` (floating tag), triggering hadolint DL3006. Build tools (pip, setuptools, wheel) remained in the final image with HIGH CVEs.

**Solution:** Pinned builder to `python:3.11.15-alpine3.24`. Added `pip uninstall -y pip setuptools wheel` in the final stage to remove build tools not needed at runtime.

---

## Fix 9

**File:** `api/Dockerfile`, `worker/Dockerfile`
**Lines:** 25–26

**Problem:** `ENV PYTHONPATH=...` referenced `$PYTHONPATH` which was never previously defined, causing a Docker build `UndefinedVar` warning.

**Solution:** Removed the self-reference — set `PYTHONPATH=/install/lib/python3.11/site-packages` directly.

---

## Fix 10

**File:** `.github/workflows/ci-cd.yml`
**Lines:** build, security-scan, integration-test, deploy jobs

**Problem:** Images were passed between jobs as `.tar.gz` artifacts (three separate files), which did not satisfy the assignment requirement of pushing to a local registry.

**Solution:** Added a `registry:2` service container to each job. The `build` job pushes images to it, saves the registry volume as a single artifact. Subsequent jobs restore the volume and pull images from the registry.

---

## Fix 11

**File:** `scripts/rolling_update.sh`

**Problem:** Rolling update started the new container with the same host port bindings as the old container, causing "port already allocated" error since the old container was still running.

**Solution:** New container starts without host port bindings, gets health-checked via its internal Docker network IP using `curl` from the runner host, then the old container is stopped and the new one is recreated with the original port bindings.

---

## Fix 12

**File:** `docker-compose.yml`
**Lines:** frontend healthcheck

**Problem:** Frontend healthcheck used `curl` which is not installed in the Alpine-based Node image.

**Solution:** Replaced with a `node -e` healthcheck using the built-in `http` module.
