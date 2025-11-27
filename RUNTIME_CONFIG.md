# Runtime Configuration Approach

This document explains the runtime configuration approach used to solve the backend URL dependency issue.

## The Problem

Previously, the frontend needed the backend URL at **build time** because Vite bakes environment variables into the JavaScript bundle during compilation. This created a chicken-and-egg problem:
- We need to build the frontend container to push it to the registry
- But we need the backend URL to build the frontend
- But we only know the backend URL after deploying Container Apps

## The Solution: Runtime Configuration

Instead of baking the backend URL into the build, we now read it from a `config.json` file at runtime. This file is generated when the container starts, using an environment variable.

## How It Works

### 1. Build Time
- Frontend is built **without** any backend URL
- No build arguments needed
- The build is environment-agnostic

### 2. Container Startup
- When the frontend container starts, it reads the `BACKEND_URL` environment variable
- A startup script generates `/usr/share/nginx/html/config.json` with the backend URL
- This file is served by nginx and accessible to the frontend JavaScript

### 3. Runtime
- Frontend JavaScript loads `config.json` on app initialization
- The backend URL is read from this file
- All API calls use this runtime-configured URL

## Implementation Details

### Frontend Changes

1. **Config Utility** (`frontend/src/utils/config.js`):
   - Loads `config.json` from the public directory
   - Falls back to build-time env vars for local development
   - Provides synchronous and asynchronous access to the backend URL

2. **API Files Updated**:
   - All API files now use `getBackendUrlSync()` from the config utility
   - No more `import.meta.env.VITE_BACKEND_URL` references

3. **AppContext Updated**:
   - Uses the config utility to get the backend URL
   - Updates when config loads asynchronously

### Dockerfile Changes

The Dockerfile now:
1. Builds the frontend without any backend URL
2. Includes a startup script that generates `config.json` from the `BACKEND_URL` environment variable
3. Serves `config.json` with no-cache headers to ensure fresh reads

### Terraform Changes

The Container Apps Terraform configuration:
- Sets the `BACKEND_URL` environment variable for the frontend container
- Uses the backend Container App's FQDN: `https://${azurerm_container_app.backend.ingress[0].fqdn}`

### Build Pipeline Changes

The build pipeline:
- **No longer** requires `VITE_BACKEND_URL` build argument
- Simply builds and pushes containers
- No dependency on backend URL being known at build time

## Deployment Workflow

### Simple Deployment Flow

1. **Deploy Infrastructure** (Terraform):
   ```bash
   cd infra/terraform/container-apps
   terraform apply -var-file=dev/dev.tfvars
   ```
   - Creates Container Apps
   - Sets `BACKEND_URL` environment variable on frontend container

2. **Build and Push Containers**:
   - Run the build pipeline (or build locally)
   - No special configuration needed
   - Containers are pushed to ACR

3. **Container Apps Start**:
   - Frontend container reads `BACKEND_URL` environment variable
   - Generates `config.json` at startup
   - Frontend JavaScript loads config and uses the backend URL

### No More Chicken-and-Egg Problem!

- ✅ Build containers without knowing backend URL
- ✅ Deploy infrastructure independently
- ✅ Backend URL is configured at runtime
- ✅ Same container image works for all environments (just change env var)

## Benefits

1. **Simplified Build Process**: No need to pass backend URL at build time
2. **Environment Flexibility**: Same image works for dev/stage/prod
3. **No Variable Group Dependencies**: Build pipeline doesn't need backend URL
4. **Easier Local Development**: Still works with `.env` files for local dev
5. **Better Separation of Concerns**: Build vs. runtime configuration

## Local Development

For local development, you can still use `.env` files:

```bash
# frontend/.env
VITE_BACKEND_URL=http://localhost:5000
```

The config utility will use this as a fallback if `config.json` is not available.

## Troubleshooting

### Frontend can't connect to backend

1. Check that `BACKEND_URL` environment variable is set in Container App
2. Verify `config.json` is being generated:
   ```bash
   # In container
   cat /usr/share/nginx/html/config.json
   ```
3. Check browser console for config loading errors
4. Verify nginx is serving `config.json`:
   ```bash
   curl https://your-frontend-url/config.json
   ```

### Config not loading

- Check browser network tab for `/config.json` request
- Verify nginx configuration includes the config.json location
- Check that the startup script ran successfully (container logs)

## Migration Notes

If you're migrating from the build-time approach:

1. Remove `VITE_BACKEND_URL` build arguments from pipelines
2. Update Terraform to set `BACKEND_URL` environment variable
3. Deploy new frontend containers
4. Verify `config.json` is generated correctly

The runtime approach is backward compatible - if `config.json` fails to load, it falls back to `VITE_BACKEND_URL` env var (for local dev).

