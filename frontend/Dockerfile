# Stage 1: Dependencies
FROM node:18-alpine AS deps

WORKDIR /app

# Copy package files for better layer caching
COPY package*.json ./

# Install only production dependencies
RUN npm install --production --ignore-scripts


# Stage 2: Final production image
FROM node:18-alpine AS production

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1000 appgroup && adduser -D -u 1000 -G appgroup appuser

# Copy production dependencies and application code from deps stage
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=deps --chown=appuser:appgroup /app/app.js ./
COPY --from=deps --chown=appuser:appgroup /app/views ./views

# Set runtime environment defaults
ENV NODE_ENV=production
ENV PORT=3000

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', res => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["npm", "start"]
