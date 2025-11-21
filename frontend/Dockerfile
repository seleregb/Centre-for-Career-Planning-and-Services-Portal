# Build stage
FROM node:18-alpine AS builder
WORKDIR /app

# Accept build arguments for Vite environment variables
ARG VITE_BACKEND_URL
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code and .env file (if it exists)
COPY . .
# Create .env file from build arg if VITE_BACKEND_URL is provided and .env doesn't exist
RUN if [ -n "$VITE_BACKEND_URL" ] && [ ! -f .env ]; then \
      echo "VITE_BACKEND_URL=$VITE_BACKEND_URL" > .env; \
    fi

# Build the application
RUN npm run build

# Production stage
FROM nginx:stable-alpine

# Copy built assets from builder stage
# Vite builds to 'dist' directory by default
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration for SPA routing
RUN echo 'server { \
    listen 5173; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
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

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
