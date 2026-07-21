# Stage 1: Build dependencies
FROM python:3.11.15-alpine3.24 AS builder

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final production image
FROM python:3.11.15-alpine3.24

WORKDIR /app

# Remove pip/setuptools/wheel — not needed at runtime
RUN pip uninstall -y pip setuptools wheel 2>/dev/null || true

# Create non-root user
RUN addgroup -g 1000 appgroup && adduser -D -u 1000 -G appgroup appuser \
    && chown -R appuser:appgroup /app

# Copy dependency installation from builder
COPY --from=builder /install /install

# Copy application code
COPY main.py .

ENV PATH=/install/bin:$PATH
ENV PYTHONPATH=/install/lib/python3.11/site-packages:$PYTHONPATH

USER appuser

EXPOSE 8000

CMD ["/install/bin/uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
