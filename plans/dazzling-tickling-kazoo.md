# Vercel Configuration Diagnosis Report

## Executive Summary

**Root Cause Found:** Your OAuth failure is caused by **missing SPA fallback routing** in `vercel.json`.

When Google redirects back to `/auth/callback?token=...`, Vercel looks for a literal file at that path. Since it doesn't exist (it's a React Router route), Vercel returns **404 NOT_FOUND**.

## The Fix (One Line Change)

Update `vercel.json` to add the SPA fallback rewrite:

```json
{
  "version": 2,
  "outputDirectory": "frontend/dist",
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/index.py" },
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

The second rewrite catches ALL non-API routes and serves `index.html`, letting React Router handle client-side routing.

---

## Current Configuration

**vercel.json:**
```json
{
  "version": 2,
  "outputDirectory": "frontend/dist",
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/index.py" }
  ]
}
```

---

## Issues Found

### CRITICAL: Missing SPA Fallback Routing

**Problem:** Your React app uses React Router for client-side routing, but there's no fallback rule to serve `index.html` for non-file routes.

**What happens:**
- User visits `/extraction` directly (or refreshes on that page)
- Vercel looks for a file at `/extraction`
- No file exists → **404 error**

**Evidence:** The recent commits show you've been iterating on this:
- `239dadc` - "Fix SPA routing: add filesystem handler for React Router"
- `ee470fa` - "Fix static file paths: remove /frontend prefix from routes"

But the current simplified config lost the SPA fallback.

**Fix needed:** Add a catch-all rewrite:
```json
{
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/index.py" },
    { "source": "/((?!api/).*)", "destination": "/index.html" }
  ]
}
```

---

### MODERATE: Implicit Python Detection May Fail

**Problem:** The simplified config relies on Vercel auto-detecting the Python serverless function in `/api/index.py`. This works most of the time, but explicit configuration is more reliable.

**Risk:** If auto-detection fails, the API returns 404s or static file responses instead of running Python.

**Recommended explicit config:**
```json
{
  "functions": {
    "api/index.py": {
      "runtime": "python3.9"
    }
  }
}
```

**Note:** Commit `19029ff` says "remove functions property (incompatible with builds)" - this was true with the old `builds` array, but should work with the current simplified config.

---

### MODERATE: CORS Configuration Fragility

**Location:** `backend/app/main.py:23-35`

**Current logic:**
```python
allowed_origins = ["http://localhost:3000", "http://localhost:5173"]
if settings.frontend_url and settings.frontend_url not in allowed_origins:
    allowed_origins.append(settings.frontend_url)

vercel_url = os.getenv("VERCEL_URL")
if vercel_url:
    allowed_origins.append(f"https://{vercel_url}")
```

**Issues:**
1. `VERCEL_URL` contains just the domain (e.g., `my-app-123.vercel.app`), not the full URL
2. On preview deployments, `VERCEL_URL` changes each time
3. If `FRONTEND_URL` isn't set in Vercel env vars, CORS could fail

**However:** Since frontend and API are on the same origin in production, CORS headers are technically not needed for same-origin requests. This is mostly a concern for development and preview deploys.

---

### LOW: OAuth Callback URL Configuration

**Location:** `backend/app/routers/auth.py:64-77`

```python
def get_callback_url(request: Request) -> str:
    forwarded_host = request.headers.get("x-forwarded-host")
    forwarded_proto = request.headers.get("x-forwarded-proto", "https")

    if forwarded_host:
        return f"{forwarded_proto}://{forwarded_host}/api/auth/callback"

    return str(request.url_for("google_callback"))
```

**Risk:** The callback URL is dynamically constructed. Google OAuth requires **exact match** of the registered callback URL. If preview deployments have different URLs, OAuth will fail unless all URLs are registered in Google Console.

**Recommendation:** For production, hardcode the callback URL from an environment variable rather than constructing it dynamically.

---

### LOW: requirements.txt Location

You have two requirements files:
- `/requirements.txt` (root) - Used by Vercel
- `/backend/requirements.txt` - For local development

This is correct, but ensure Vercel is reading from root. The auto-detection should pick up `/requirements.txt`.

---

## Verification Checklist

After fixing, verify:

1. **Direct URL access:** Navigate directly to `https://your-app.vercel.app/extraction` (should load the app, not 404)
2. **API health:** Visit `https://your-app.vercel.app/api/health` (should return `{"status": "healthy"}`)
3. **OAuth flow:** Complete a full login cycle
4. **Page refresh:** Refresh on any route (should not 404)

---

## Recommended Fix

Update `vercel.json` to:

```json
{
  "version": 2,
  "outputDirectory": "frontend/dist",
  "functions": {
    "api/index.py": {
      "runtime": "python3.9"
    }
  },
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/index.py" },
    { "source": "/((?!api/).*)", "destination": "/index.html" }
  ]
}
```

This adds:
1. Explicit Python runtime declaration
2. SPA fallback for React Router routes

---

## Files to Modify

1. **vercel.json** - Add SPA fallback and explicit Python runtime

---

---

## OAuth-Specific Diagnosis (User Reported Issue)

### OAuth Flow on Vercel

```
1. User clicks Login → /api/auth/google
2. Backend builds Google OAuth URL with callback: /api/auth/callback
3. Google authenticates user → redirects to /api/auth/callback?code=xxx
4. Backend exchanges code → creates JWT → redirects to {FRONTEND_URL}/auth/callback?token=jwt
5. Frontend stores token → fetches /api/auth/me
```

### Most Likely OAuth Failure Points

#### 1. FRONTEND_URL Not Set in Vercel Environment (HIGH PROBABILITY)

**Location:** `backend/app/config.py:74`
```python
frontend_url: str = os.getenv("FRONTEND_URL", "http://localhost:5173")
```

**Problem:** If `FRONTEND_URL` is not set in Vercel's Environment Variables, after successful Google auth, the backend redirects to `http://localhost:5173/auth/callback?token=xxx` instead of your production URL.

**Symptom:** After clicking "Login with Google" and authenticating, you get redirected to localhost (which fails) instead of your Vercel app.

**Fix:** In Vercel Dashboard → Settings → Environment Variables, add:
```
FRONTEND_URL=https://your-app.vercel.app
```

---

#### 2. Google OAuth Callback URL Not Registered (HIGH PROBABILITY)

**Problem:** Google OAuth requires exact match of redirect URIs. Your Vercel app URL must be registered in Google Cloud Console.

**Symptom:** Error message: "Error 400: redirect_uri_mismatch"

**Fix:** Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials):
1. Select your OAuth 2.0 Client ID
2. Under "Authorized redirect URIs", add:
   ```
   https://your-app.vercel.app/api/auth/callback
   ```

---

#### 3. Missing Environment Variables in Vercel

**Required env vars for OAuth:**
```
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
JWT_SECRET_KEY=your-production-secret-key
FRONTEND_URL=https://your-app.vercel.app
```

**Symptom:** 500 error when clicking Login, or error "Google OAuth not configured"

**Check:** Vercel Dashboard → Settings → Environment Variables

---

#### 4. Dynamic Callback URL Construction Issue

**Location:** `backend/app/routers/auth.py:64-77`

The callback URL is constructed dynamically:
```python
def get_callback_url(request: Request) -> str:
    forwarded_host = request.headers.get("x-forwarded-host")
    forwarded_proto = request.headers.get("x-forwarded-proto", "https")

    if forwarded_host:
        return f"{forwarded_proto}://{forwarded_host}/api/auth/callback"

    return str(request.url_for("google_callback"))
```

**Risk:** If Vercel doesn't send `x-forwarded-host` header, the fallback `url_for()` may generate wrong URL.

---

### OAuth Debugging Steps

1. **Check Vercel Function Logs:**
   - Vercel Dashboard → Deployments → Functions tab
   - Look for errors when hitting `/api/auth/google`

2. **Test API directly:**
   - Visit `https://your-app.vercel.app/api/health` - should return `{"status": "healthy"}`
   - Visit `https://your-app.vercel.app/api/auth/google` - should redirect to Google

3. **Check browser console:**
   - Look for CORS errors or redirect issues

---

## Summary

| Issue | Severity | Status |
|-------|----------|--------|
| FRONTEND_URL not set in Vercel | CRITICAL | Likely cause of OAuth failure |
| Google OAuth callback not registered | CRITICAL | Must register Vercel URL |
| Missing SPA fallback | CRITICAL | Causes 404 on refresh |
| Missing env vars (GOOGLE_*) | HIGH | Required for OAuth |
| Implicit Python detection | MODERATE | Recommended fix |
| CORS fragility | MODERATE | Works for production |
| Dynamic callback URL | LOW | Works but fragile |
