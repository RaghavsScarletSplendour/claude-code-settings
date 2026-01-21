# Fix: SPA Routing Fallback on Vercel

## Problem
After Google OAuth, redirect to `/auth/callback?token=...` returns Vercel 404. The current config doesn't have a fallback to serve `index.html` for client-side routes.

## Solution
Add a catch-all rewrite to serve `index.html` for non-API routes that don't match static files.

## File to Modify

### `/vercel.json`

**Current:**
```json
{
  "version": 2,
  "outputDirectory": "frontend/dist",
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/index.py" }
  ]
}
```

**Updated:**
```json
{
  "version": 2,
  "outputDirectory": "frontend/dist",
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/index.py" },
    { "source": "/:path*", "destination": "/index.html" }
  ]
}
```

The catch-all `/:path*` will serve `index.html` for any route that doesn't match a static file, allowing React Router to handle the route.

## Verification
1. Push changes
2. Wait for deployment
3. Go to https://jdjones-store-order-automation.vercel.app
4. Click "Sign in with Google"
5. After OAuth, should redirect to `/auth/callback` and React handles the token
