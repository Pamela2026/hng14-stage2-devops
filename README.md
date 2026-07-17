# hng14-stage2-devops

## Environment variables

### API
- `PORT`: API server port (default `8000`)
- `REDIS_HOST`: Redis hostname (default `localhost`)
- `REDIS_PORT`: Redis port (default `6379`)
- `REDIS_URL`: Optional Redis connection URL
- `CORS_ORIGINS`: Comma-separated allowed frontend origins (default `http://localhost:3000`)

### Frontend
- `PORT`: Frontend server port (default `3000`)
- `API_URL`: Backend API URL (default `http://localhost:8000`)

### Worker
- `REDIS_HOST`: Redis hostname (default `localhost`)
- `REDIS_PORT`: Redis port (default `6379`)
- `REDIS_URL`: Optional Redis connection URL
- `WORKER_DELAY`: Seconds to simulate work (default `2`)

## Run

### API
```bash
cd api
uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
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
python worker.py
```
