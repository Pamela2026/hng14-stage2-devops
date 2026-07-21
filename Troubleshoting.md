# Additional Fixes

## 1. Frontend Dockerfile Fixes

**Error 1: User ID Collision**
- Problem: The frontend Dockerfile created a group/user with `gid`/`uid` 1000, which may conflict with the Node.js base image.
- Fix: Changed the group/user IDs to `1001`.

**Error 2: Missing Application Files**
- Problem: The container attempted to copy `app.js` and `views` from the `deps` stage instead of the build context, causing build failures.
- Fix: Copy application files from the build context using:
```dockerfile
COPY --chown=appuser:appgroup package*.json ./
COPY --chown=appuser:appgroup app.js ./
COPY --chown=appuser:appgroup views ./views
```

**Error 3: Container Start Command**
- Problem: The old Dockerfile used `CMD ["npm", "start"]` but the container should start the application directly.
- Fix: Updated the runtime command to:
```dockerfile
CMD ["node", "app.js"]
```

## 2. Worker Code Fixes

**Error: Unhandled Redis Socket Timeout**
- Problem: The worker crashed on Redis socket errors or timeouts because there was no error handling around `r.brpop()`.
- Fix: Added a try/except block around the queue polling loop to log failures and retry.
