import redis
import time
import os
import signal
import sys

REDIS_URL = os.getenv("REDIS_URL")
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
WORKER_DELAY = int(os.getenv("WORKER_DELAY", "2"))

if REDIS_URL:
    r = redis.Redis.from_url(REDIS_URL)
else:
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT)


def process_job(job_id):
    print(f"Processing job {job_id}")
    time.sleep(WORKER_DELAY)  # simulate work
    r.hset(f"job:{job_id}", "status", "completed")
    print(f"Done: {job_id}")


def exit_gracefully(signum, frame):
    print("Worker shutting down...")
    sys.exit(0)

signal.signal(signal.SIGTERM, exit_gracefully)
signal.signal(signal.SIGINT, exit_gracefully)

while True:
    job = r.brpop("job", timeout=5)
    if job:
        _, job_id = job
        process_job(job_id.decode())