# Stage 1: Dependencies
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files for better layer caching
COPY package*.json ./

# Install only production dependencies
RUN npm install --production --ignore-scripts


# Stage 2: Final production image
FROM node:20-alpine AS production

WORKDIR /app

# Upgrade Alpine packages and npm (clears tar CVE bundled in npm), then create non-root user
RUN apk update && apk upgrade --no-cache \
    && npm install -g npm@10.9.2 \
    && addgroup -g 1001 appgroup && adduser -D -u 1001 -G appgroup appuser

# Copy production dependencies and application code from deps stage
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --chown=appuser:appgroup package*.json ./
COPY --chown=appuser:appgroup app.js ./
COPY --chown=appuser:appgroup views ./views

# Set runtime environment defaults
ENV NODE_ENV=production
ENV PORT=3000

USER appuser

EXPOSE 3000

CMD ["node", "app.js"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', res => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"


