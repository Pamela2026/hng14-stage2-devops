# hng14-stage2-devops

A containerised job-queue application with a FastAPI backend, Node.js frontend, and Python worker — connected via Redis. Includes a full 6-stage CI/CD pipeline on GitHub Actions with no external cloud accounts or secrets required.

---

## Architecture

```
Browser
  │
  ▼
Frontend (Node.js / Express) :3000
  │  POST /submit  →  GET /status/:id
  ▼
API (FastAPI / Python) :8000
  │  lpush job_id  │  hget job status
  ▼
Redis :6379
  ▲
  │  brpop job_id  │  hset job status=completed
Worker (Python)
```

- **Frontend** — serves a static HTML page, proxies job submission and status polling to the API
- **API** — creates jobs (UUID), pushes to Redis queue, returns job status
- **Worker** — blocks on Redis queue, processes jobs with a configurable delay, marks them completed
- **Redis** — job queue (`LPUSH`/`BRPOP`) and job state store (`HSET`/`HGET`)

---

## Prerequisites

- Docker >= 24
- Docker Compose >= 2.20
- Python 3.11 (local development only)
- Node.js 20 (local development only)

---

## Environment variables

Copy `.env.example` to `.env` and fill in values before running.

### Redis
| Variable | Default | Description |
|---|---|---|
| `REDIS_IMAGE` | `redis:7.0-alpine` | Redis Docker image |
| `REDIS_HOST` | `redis` | Redis hostname |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_URL` | — | Full Redis URL, overrides host/port if set |
| `REDIS_CONTAINER_NAME` | `hng14-redis` | Container name |
| `REDIS_CPU_LIMIT` | `0.25` | CPU limit |
| `REDIS_MEMORY_LIMIT` | `600M` | Memory limit |

### API
| Variable | Default | Description |
|---|---|---|
| `API_IMAGE` | — | Docker image reference |
| `API_CONTAINER_NAME` | `hng14-api` | Container name |
| `API_HOST_PORT` | `8000` | Host port |
| `API_SERVICE_PORT` | `8000` | Container port |
| `CORS_ORIGINS` | `http://localhost:3000` | Comma-separated allowed origins |
| `API_CPU_LIMIT` | `0.25` | CPU limit |
| `API_MEMORY_LIMIT` | `500M` | Memory limit |

### Frontend
| Variable | Default | Description |
|---|---|---|
| `FRONTEND_IMAGE` | — | Docker image reference |
| `FRONTEND_CONTAINER_NAME` | `hng14-frontend` | Container name |
| `FRONTEND_HOST_PORT` | `3000` | Host port |
| `FRONTEND_SERVICE_PORT` | `3000` | Container port |
| `API_URL` | `http://api:8000` | Backend API URL |
| `FRONTEND_CPU_LIMIT` | `0.25` | CPU limit |
| `FRONTEND_MEMORY_LIMIT` | `500M` | Memory limit |

### Worker
| Variable | Default | Description |
|---|---|---|
| `WORKER_IMAGE` | — | Docker image reference |
| `WORKER_CONTAINER_NAME` | `hng14-worker` | Container name |
| `WORKER_DELAY` | `2` | Seconds to simulate work |
| `WORKER_CPU_LIMIT` | `0.25` | CPU limit |
| `WORKER_MEMORY_LIMIT` | `500M` | Memory limit |

---

## Build instructions

```bash
# Build all images
docker build -t hng14-api:latest api/
docker build -t hng14-frontend:latest frontend/
docker build -t hng14-worker:latest worker/
```

Each image uses a multi-stage build:
- **Stage 1 (builder)** — installs dependencies
- **Stage 2 (final)** — copies only the installed packages and app code, strips build tools

---

## Docker Compose commands

```bash
# Start full stack (detached, wait for health checks)
docker compose up -d --wait

# View logs
docker compose logs -f

# Stop and remove containers and volumes
docker compose down -v

# Restart a single service
docker compose restart api
```

---

## Running locally

### API
```bash
cd api
pip install -r requirements-dev.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend
```bash
cd frontend
npm install
npm start
```

### Worker
```bash
cd worker
pip install -r requirements.txt
python worker.py
```

> Redis must be running locally or `REDIS_URL` must point to a reachable instance.

---

## CI/CD explanation

The pipeline runs entirely on `ubuntu-latest` GitHub Actions runners. No external cloud accounts, registries, or secrets are required.

### Stages

| Stage | Job | What it does |
|---|---|---|
| 1 | Lint | flake8 (api, worker), eslint (frontend), hadolint (all Dockerfiles) |
| 2 | Test | pytest with coverage report uploaded as artifact |
| 3 | Build | Builds all 3 Docker images, pushes to a local `registry:2` service container, saves registry data as artifact |
| 4 | Security Scan | Trivy scans all 3 images — table format for log visibility, SARIF format enforced (exit 1 on CRITICAL) |
| 5 | Integration Test | Starts full stack via Docker Compose, submits a job, polls until completed |
| 6 | Deploy | main branch only — starts stack, runs rolling_update.sh for api and frontend, direct swap for worker |

### Image passing between jobs

Images are built once in the `build` job and pushed to a `registry:2` service container. The registry's `/var/lib/registry` volume is saved as a GitHub artifact and restored in each subsequent job, which starts its own `registry:2` instance and pulls from it.

### Rolling update

`scripts/rolling_update.sh` performs a near-zero-downtime deployment:
1. Starts the new container on the Docker network without host port bindings
2. Health-checks it via its internal IP using `curl` from the runner
3. Once healthy, stops and removes the old container
4. Recreates the new container with the original host port bindings

---

## Testing

```bash
cd api
pip install -r requirements-dev.txt
pytest tests/ --cov=. --cov-report=term-missing -v
```

Tests cover:
- Job creation returns a UUID
- Job status retrieval
- 404 on missing job
- Redis `lpush`/`hset` call assertions
- Bytes decoding of Redis responses

---

## Deployment

The deploy stage runs on `main` branch pushes only. It simulates a production environment directly on the GitHub runner:

1. Restores images from the local registry artifact
2. Creates a Docker network and starts Redis
3. Starts the current stack (api, frontend, worker)
4. Runs rolling updates for api and frontend
5. Direct swap for worker (no HTTP endpoint)
6. Verifies the stack is healthy
7. Cleans up all containers and the network
