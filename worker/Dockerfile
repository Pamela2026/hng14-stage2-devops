# Stage 1: Build dependencies
FROM python:3.11.15-alpine3.24 AS builder

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final production image
FROM gcr.io/distroless/python3-debian12

WORKDIR /app

# Copy dependency installation from builder
COPY --from=builder /install /install

# Copy application code
COPY worker.py .

ENV PATH=/install/bin:$PATH
ENV PYTHONPATH=/install/lib/python3.11/site-packages:$PYTHONPATH

CMD ["/install/bin/python", "worker.py"]
