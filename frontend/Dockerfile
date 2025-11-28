# Build stage
FROM node:18-alpine AS builder
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build the application (no backend URL needed at build time)
RUN npm run build

# Production stage
FROM nginx:stable-alpine

# Install envsubst for environment variable substitution
RUN apk add --no-cache gettext

# Copy built assets from builder stage
# Vite builds to 'dist' directory by default
COPY --from=builder /app/dist /usr/share/nginx/html

# Create a script to generate config.json from environment variable at startup
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo '' >> /docker-entrypoint.sh && \
    echo '# Generate config.json from BACKEND_URL environment variable' >> /docker-entrypoint.sh && \
    echo 'BACKEND_URL="${BACKEND_URL:-http://localhost:5500}"' >> /docker-entrypoint.sh && \
    echo 'echo "{\"BACKEND_URL\": \"$BACKEND_URL\"}" > /usr/share/nginx/html/config.json' >> /docker-entrypoint.sh && \
    echo 'echo "Generated config.json with BACKEND_URL=$BACKEND_URL"' >> /docker-entrypoint.sh && \
    echo '' >> /docker-entrypoint.sh && \
    echo '# Start nginx' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Copy custom nginx configuration for SPA routing
RUN echo 'server { \
    listen 5173; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /config.json { \
        add_header Cache-Control "no-cache, no-store, must-revalidate"; \
        add_header Pragma "no-cache"; \
        add_header Expires "0"; \
    } \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 5173

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5173/health || exit 1

# Use custom entrypoint to generate config.json at startup
ENTRYPOINT ["/docker-entrypoint.sh"]
