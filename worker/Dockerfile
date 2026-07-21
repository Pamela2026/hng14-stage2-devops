# Stage 1: Build dependencies
FROM python:3.11-alpine AS builder

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final production image
FROM python:3.11-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1000 appgroup && adduser -D -u 1000 -G appgroup appuser \
    && chown -R appuser:appgroup /app

# Copy dependency installation from builder
COPY --from=builder /install /install

# Upgrade bundled pip/wheel/setuptools to clear known CVEs
RUN pip install --no-cache-dir pip==26.1.2 wheel==0.46.2

# Copy application code
COPY worker.py .

ENV PATH=/install/bin:$PATH
ENV PYTHONPATH=/install/lib/python3.11/site-packages:$PYTHONPATH

USER appuser

CMD ["python", "worker.py"]
