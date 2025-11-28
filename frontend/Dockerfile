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

# Install wget for health checks and gettext for environment variable substitution
RUN apk add --no-cache wget gettext

# Copy built assets from builder stage
# Vite builds to 'dist' directory by default
COPY --from=builder /app/dist /usr/share/nginx/html

# Create a script to generate config.json from environment variable at startup
# In container app setup, nginx proxies /api/* to backend, so BACKEND_URL should be empty (relative URLs)
# This allows browser to make requests to the same origin (frontend ingress), and nginx proxies to backend
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo '' >> /docker-entrypoint.sh && \
    echo '# Generate config.json from BACKEND_URL environment variable' >> /docker-entrypoint.sh && \
    echo '# Default to empty string for relative URLs (nginx proxies /api/* to backend container)' >> /docker-entrypoint.sh && \
    echo 'BACKEND_URL="${BACKEND_URL:-}"' >> /docker-entrypoint.sh && \
    echo '' >> /docker-entrypoint.sh && \
    echo '# Generate config.json (empty string means relative URLs)' >> /docker-entrypoint.sh && \
    echo 'if [ -z "$BACKEND_URL" ]; then' >> /docker-entrypoint.sh && \
    echo '  echo "{\"BACKEND_URL\": \"\"}" > /usr/share/nginx/html/config.json' >> /docker-entrypoint.sh && \
    echo '  echo "✅ Generated config.json with BACKEND_URL=empty (using relative URLs, nginx proxies to backend)"' >> /docker-entrypoint.sh && \
    echo 'else' >> /docker-entrypoint.sh && \
    echo '  echo "{\"BACKEND_URL\": \"$BACKEND_URL\"}" > /usr/share/nginx/html/config.json' >> /docker-entrypoint.sh && \
    echo '  echo "✅ Generated config.json with BACKEND_URL=$BACKEND_URL"' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo '' >> /docker-entrypoint.sh && \
    echo '# Start nginx' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Copy custom nginx configuration for SPA routing
# Proxies /api/* requests to backend container on localhost:5500
RUN echo 'server { \
    listen 5173; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Proxy API requests to backend container \
    location /api/ { \
        proxy_pass http://localhost:5500/api/; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
        proxy_cache_bypass $http_upgrade; \
    } \
    \
    # Serve config.json with no-cache headers \
    location /config.json { \
        add_header Cache-Control "no-cache, no-store, must-revalidate"; \
        add_header Pragma "no-cache"; \
        add_header Expires "0"; \
    } \
    \
    # Health check endpoint \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
        add_header Content-Type text/plain; \
    } \
    \
    # SPA routing - serve index.html for all other routes \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 5173

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5173/health || exit 1

# Use custom entrypoint to generate config.json at startup
ENTRYPOINT ["/docker-entrypoint.sh"]
