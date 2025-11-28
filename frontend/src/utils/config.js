// Runtime configuration utility
// Reads backend URL from config.json file (generated at container startup)
// or falls back to build-time environment variables

let backendUrl = null;
let configPromise = null;

/**
 * Loads configuration from config.json file
 * This file is generated at container startup from environment variables
 */
function loadConfig() {
  if (configPromise) {
    return configPromise;
  }

  configPromise = (async () => {
    try {
      // Try to fetch config.json from public directory
      const response = await fetch('/config.json', { 
        cache: 'no-store',
        headers: {
          'Cache-Control': 'no-cache'
        }
      });
      
      if (response.ok) {
        const config = await response.json();
        // Empty string is valid - it means use relative URLs (nginx proxies to backend)
        const url = config.BACKEND_URL !== undefined ? config.BACKEND_URL : (config.backendUrl !== undefined ? config.backendUrl : config.VITE_BACKEND_URL);
        if (url !== undefined && url !== null) {
          backendUrl = url === '' ? '' : url;
          console.log('✅ Loaded backend URL from config.json:', backendUrl || '(empty - using relative URLs)');
          return backendUrl;
        }
      }
    } catch (error) {
      console.warn('⚠️ Failed to load config.json:', error.message);
    }

    // Fallback to build-time env var (for development)
    if (import.meta.env.VITE_BACKEND_URL !== undefined) {
      backendUrl = import.meta.env.VITE_BACKEND_URL || '';
      console.log('📦 Using build-time VITE_BACKEND_URL:', backendUrl || '(empty - using relative URLs)');
      return backendUrl;
    }

    // Final fallback for local development (only if not in production)
    // In production (container app), empty string means nginx proxies to backend
    // In local dev, default to localhost:5500
    if (import.meta.env.MODE === 'development') {
      backendUrl = 'http://localhost:5500';
      console.warn('⚠️ Using default backend URL for local development:', backendUrl);
    } else {
      backendUrl = '';
      console.log('✅ Using relative URLs (nginx will proxy to backend)');
    }
    return backendUrl;
  })();

  return configPromise;
}

/**
 * Gets the backend URL
 * This function handles both async and sync cases
 * For most use cases, call this and it will return the URL (may be async on first call)
 */
export function getBackendUrl() {
  // Check if backendUrl has been set (including empty string for relative URLs)
  if (backendUrl !== null && backendUrl !== undefined) {
    return backendUrl;
  }
  
  // Start loading if not already started
  if (!configPromise) {
    loadConfig();
  }
  
  // Return fallback while loading
  // Use relative URLs in production (empty string), localhost in dev
  if (import.meta.env.MODE === 'development') {
    return import.meta.env.VITE_BACKEND_URL || 'http://localhost:5500';
  }
  return import.meta.env.VITE_BACKEND_URL || '';
}

/**
 * Gets the backend URL synchronously
 * Use this for immediate access (will use fallback if config not loaded yet)
 */
export function getBackendUrlSync() {
  if (backendUrl !== null && backendUrl !== undefined) {
    return backendUrl;
  }
  // Use relative URLs in production (empty string), localhost in dev
  if (import.meta.env.MODE === 'development') {
    return import.meta.env.VITE_BACKEND_URL || 'http://localhost:5500';
  }
  return import.meta.env.VITE_BACKEND_URL || '';
}

/**
 * Initialize config immediately on module load
 * This ensures config is loaded as early as possible
 */
loadConfig().catch(err => {
  console.error('❌ Error loading config:', err);
});

// Export the promise for components that need to wait for config
export { configPromise };

