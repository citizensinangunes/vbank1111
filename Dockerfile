# Production-ready Next.js Dockerfile for Self-Hosting
# Multi-stage build for optimal performance

# Build stage
FROM node:18-alpine AS builder

# Install system dependencies for PDF processing
RUN apk add --no-cache \
    poppler-utils \
    python3 \
    make \
    g++ \
    libc6-compat

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production --silent

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    poppler-utils \
    bash \
    curl \
    sqlite

WORKDIR /app

# Create app user for security
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Create necessary directories
RUN mkdir -p /app/data /app/uploads /app/backups
RUN chown -R nextjs:nodejs /app

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/lib ./lib

# Copy additional files
COPY --chown=nextjs:nodejs scripts ./scripts

# Set correct permissions
RUN chmod +x /app/scripts/*.js

# Switch to non-root user
USER nextjs

# Environment variables
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/data || exit 1

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"] 