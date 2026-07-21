# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final production image
FROM python:3.11-slim

WORKDIR /app

# Upgrade OS packages to clear known CVEs, then create non-root user
RUN apt-get update && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Copy dependency installation from builder
COPY --from=builder /install /install

# Copy application code
COPY --from=builder /app/requirements.txt ./requirements.txt
COPY worker.py .

ENV PATH=/install/bin:$PATH
ENV PYTHONPATH=/install/lib/python3.11/site-packages:$PYTHONPATH

USER appuser

CMD ["python", "worker.py"]
