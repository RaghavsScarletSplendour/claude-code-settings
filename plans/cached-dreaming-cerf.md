# Google OAuth Authentication Plan

## Overview
Add Google OAuth authentication to restrict access to company employees only.

**Approach**: Google OAuth with domain restriction - users sign in with their Google Workspace account, only `@yourcompany.com` emails allowed.

---

## Why This Is Secure

1. **No passwords stored** - Nothing to steal or brute force
2. **Google handles security** - 2FA, suspicious login detection, etc.
3. **Domain restriction** - Only company emails can authenticate
4. **JWT tokens** - Stateless, signed tokens for API access
5. **HTTPS required** - Tokens encrypted in transit

---

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   React App     │────▶│   FastAPI       │────▶│   Google OAuth  │
│                 │     │                 │     │                 │
│ 1. Click Login  │     │ 2. Redirect to  │     │ 3. User signs   │
│                 │◀────│    Google       │◀────│    in with      │
│ 6. Store JWT    │     │ 5. Issue JWT    │     │    company      │
│    Access app   │     │    if valid     │     │    Google       │
│                 │     │    domain       │     │ 4. Return code  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## Implementation Steps

### Step 1: Google Cloud Console Setup (Manual)
1. Go to https://console.cloud.google.com
2. Create new project or select existing
3. Enable "Google+ API" or "Google Identity"
4. Create OAuth 2.0 credentials (Web application)
5. Set authorized redirect URI: `http://localhost:8000/api/auth/callback`
6. Copy Client ID and Client Secret

### Step 2: Backend - Install Dependencies
```bash
cd backend && pip install python-jose[cryptography] httpx
```

### Step 3: Backend - Add Auth Configuration
**File**: `backend/app/config.py`
- Add Google OAuth client ID, secret
- Add JWT secret key
- Add allowed email domain

### Step 4: Backend - Create Auth Router
**File**: `backend/app/routers/auth.py`

Endpoints:
- `GET /api/auth/google` - Redirect to Google OAuth
- `GET /api/auth/callback` - Handle OAuth callback, issue JWT
- `GET /api/auth/me` - Get current user info
- `POST /api/auth/logout` - Clear session (optional)

### Step 5: Backend - Add Auth Middleware
**File**: `backend/app/middleware/auth.py`

- Verify JWT token on all `/api/*` routes (except `/api/auth/*`)
- Return 401 if invalid/missing token

### Step 6: Backend - Update Main App
**File**: `backend/app/main.py`

- Register auth router
- Add auth middleware

### Step 7: Frontend - Add Auth Context
**File**: `frontend/src/contexts/AuthContext.tsx`

- Store user info and token
- Provide login/logout functions
- Check auth on app load

### Step 8: Frontend - Create Login Page
**File**: `frontend/src/pages/LoginPage.tsx`

- "Sign in with Google" button
- Redirect to `/api/auth/google`

### Step 9: Frontend - Add Protected Routes
**File**: `frontend/src/App.tsx`

- Wrap routes in auth check
- Redirect to login if not authenticated

### Step 10: Frontend - Update API Client
**File**: `frontend/src/api/client.ts`

- Add JWT token to all requests
- Handle 401 responses (redirect to login)

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `backend/app/config.py` | Add OAuth config |
| `backend/app/routers/auth.py` | **NEW** - Auth endpoints |
| `backend/app/middleware/auth.py` | **NEW** - JWT verification |
| `backend/app/main.py` | Register auth router + middleware |
| `frontend/src/contexts/AuthContext.tsx` | **NEW** - Auth state management |
| `frontend/src/pages/LoginPage.tsx` | **NEW** - Login page |
| `frontend/src/App.tsx` | Add protected routes |
| `frontend/src/api/client.ts` | Add auth headers |

---

## Environment Variables Required

```bash
# Backend (.env file)
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
JWT_SECRET_KEY=generate-a-random-32-char-string
ALLOWED_EMAIL_DOMAIN=yourcompany.com
```

---

## Verification

1. Start backend: `cd backend && uvicorn app.main:app --reload`
2. Start frontend: `cd frontend && npm run dev`
3. Open http://localhost:5173
4. Should redirect to login page
5. Click "Sign in with Google"
6. Sign in with company Google account
7. Should redirect back to app, now authenticated
8. Try with non-company email - should be rejected
