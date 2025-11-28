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
        backendUrl = config.BACKEND_URL || config.backendUrl || config.VITE_BACKEND_URL;
        if (backendUrl) {
          console.log('✅ Loaded backend URL from config.json:', backendUrl);
          return backendUrl;
        }
      }
    } catch (error) {
      console.warn('⚠️ Failed to load config.json:', error.message);
    }

    // Fallback to build-time env var (for development)
    if (import.meta.env.VITE_BACKEND_URL) {
      backendUrl = import.meta.env.VITE_BACKEND_URL;
      console.log('📦 Using build-time VITE_BACKEND_URL:', backendUrl);
      return backendUrl;
    }

    // Final fallback for local development
    backendUrl = 'http://localhost:5500';
    console.warn('⚠️ Using default backend URL:', backendUrl);
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
  if (backendUrl) {
    return backendUrl;
  }
  
  // Start loading if not already started
  if (!configPromise) {
    loadConfig();
  }
  
  // Return fallback while loading
  return import.meta.env.VITE_BACKEND_URL || 'http://localhost:5500';
}

/**
 * Gets the backend URL synchronously
 * Use this for immediate access (will use fallback if config not loaded yet)
 */
export function getBackendUrlSync() {
  return backendUrl || import.meta.env.VITE_BACKEND_URL || 'http://localhost:5500';
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

