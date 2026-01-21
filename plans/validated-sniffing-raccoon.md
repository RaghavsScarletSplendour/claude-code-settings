# Fix Vercel Deployment Error - Database Optional

## Problem
After pushing Phase 2 (database setup), Vercel deployment fails with `FUNCTION_INVOCATION_FAILED`.

**Root Cause:**
1. `database.py` creates the SQLAlchemy engine at module import time (lines 36-40)
2. Without `DATABASE_URL` env var on Vercel, it defaults to SQLite at `/var/task/data/jdjones.db`
3. Vercel's filesystem is read-only, so SQLite file creation fails
4. The `init_db()` call in lifespan then crashes the function

## Solution
Make database features optional - the app should work without a database (using in-memory JWT auth like before) when `DATABASE_URL` is not configured.

---

## Files to Modify

### 1. `backend/app/db/database.py`
- Add `DATABASE_ENABLED` flag based on `DATABASE_URL` presence
- Use lazy initialization for engine (only create when needed)
- Add `get_db_optional()` dependency that returns None when DB disabled

### 2. `backend/app/main.py`
- Only call `init_db()` when database is enabled
- Import the flag and check before initialization

### 3. `backend/app/routers/auth.py`
- Make database dependency optional in OAuth callback
- Fall back to in-memory behavior (JWT-only) when DB unavailable
- Use default permissions when no database

---

## Implementation Steps

1. **Update `database.py`**:
   - Add `DATABASE_ENABLED = bool(os.getenv("DATABASE_URL"))`
   - Move engine creation inside a function (lazy init)
   - Add `get_db_optional()` that yields None when DB disabled

2. **Update `main.py`**:
   - Import `DATABASE_ENABLED` from db.database
   - Wrap `init_db()` call with `if DATABASE_ENABLED`

3. **Update `auth.py`**:
   - Import `DATABASE_ENABLED` and `get_db_optional`
   - Use optional dependency in callback
   - Add conditional logic: if db available, save user; else use defaults

---

## Verification

1. **Local without DATABASE_URL**: `unset DATABASE_URL && python -c "from app.main import app"`
2. **Run tests**: `PYTHONPATH=backend python -m pytest backend/tests/ -v`
3. **Vercel deployment**: Should succeed and work without DATABASE_URL

---

---

# JD Jones Multi-App Platform Transformation Plan

## Overview
Transform the current PO Automation codebase into a multi-app platform that supports:
- Multiple customers (Emerson, future customers)
- Multiple apps (PO Automation, Manpower Distribution, etc.)
- Unified authentication with app-level access control
- PostgreSQL database for users, permissions, and audit logs

## User Requirements
- **Priority**: Customer abstraction first, then app structure
- **Database**: Add PostgreSQL/SQLite for users, roles, audit logs (keep Excel lookup files)
- **Access Control**: Simple app-level access (which apps can each user access)

---

## Phase 1: Customer Abstraction (Current App)

**Goal**: Make PO Automation work with multiple customers without breaking Emerson functionality.

### Files to Modify

**1. Config - Add customer-aware paths**
`backend/app/config.py`
- Add `get_customer_lookups_dir(customer, app)` method
- Add `get_customer_samples_dir(customer)` method
- Keep existing paths as defaults for backward compatibility

**2. Services - Add customer parameter**
`backend/app/services/lookup_service.py`
- Add `customer` parameter to `__init__` (default: "emerson")
- Update `create_lookup_service()` to accept customer

`backend/app/services/po_checker.py`
- Add `customer` parameter to `__init__` (default: "emerson")
- Remove hardcoded path on lines 47-50

`backend/app/services/pdf_extractor.py`
- Add optional `customer` parameter
- Pass to lookup service

`backend/app/services/so_generator.py`
- Add optional `customer` parameter
- Pass to lookup service

**3. API - Add customer to endpoints**
`backend/app/routers/extraction.py`
- Add `customer: str = "emerson"` query param to all endpoints
- Validate customer against allowed list
- Pass customer to services

### Data Structure (Already Compatible)
```
data/customers/
├── emerson/           # Existing
│   ├── lookups/
│   │   ├── so_generator/
│   │   └── po_checker/
│   └── samples/
└── {new_customer}/    # Same structure for new customers
```

### Testing
- All existing tests should pass (backward compatible)
- Add tests with explicit `customer="emerson"` parameter

---

## Phase 2: Database Setup

**Goal**: Add PostgreSQL for users, permissions, audit logs.

### New Files to Create

**1. Database Models**
`backend/app/db/models.py`
```python
# Users table
- id, email, name, picture, google_id
- allowed_apps: JSON list ["po_automation", "manpower"]
- allowed_customers: JSON list ["emerson", "acme"]
- is_admin: bool
- created_at, last_login

# AuditLog table
- id, user_id, app_name, action, customer
- request_payload (JSON), response_status
- ip_address, user_agent, timestamp, duration_ms
```

**2. Database Connection**
`backend/app/db/database.py`
- SQLAlchemy async session setup
- Support both SQLite (dev) and PostgreSQL (prod)

**3. Alembic Migrations**
`backend/alembic/` directory with initial schema migration

### Files to Modify

**Config**
`backend/app/config.py`
- Add `database_url` setting
- Handle Vercel Postgres URL format conversion

**Auth Router**
`backend/app/routers/auth.py`
- On OAuth callback, create/update user in database
- Include `allowed_apps` and `allowed_customers` in JWT payload
- Update `create_jwt_token()` and `verify_jwt_token()`

### Dependencies to Add
`backend/requirements.txt`
```
sqlalchemy>=2.0.0
alembic>=1.13.0
asyncpg>=0.29.0
aiosqlite>=0.19.0
```

---

## Phase 3: App-Level Access Control

**Goal**: Enforce which apps each user can access.

### Backend Changes

**New File: Auth Dependencies**
`backend/app/dependencies/auth.py`
```python
def require_app_access(app_name: str): ...
def require_customer_access(customer: str): ...
```

**Middleware Update**
`backend/app/middleware/auth.py`
- Check if user has access to requested app
- Return 403 if denied

### Frontend Changes

**Auth Context Update**
`frontend/src/contexts/AuthContext.tsx`
- Add `allowed_apps`, `allowed_customers`, `is_admin` to User interface
- Add `hasAppAccess(appName)` and `hasCustomerAccess(customer)` methods

**Route Protection**
`frontend/src/App.tsx`
- Conditionally render routes based on `hasAppAccess()`

---

## Phase 4: Multi-App Architecture

**Goal**: Restructure codebase for multiple independent apps.

### Backend Directory Structure
```
backend/app/
├── core/                    # Shared infrastructure
│   ├── middleware/
│   ├── dependencies/
│   ├── config.py
│   └── database.py
│
├── apps/                    # Individual apps
│   ├── po_automation/
│   │   ├── routers/
│   │   ├── services/
│   │   ├── models/
│   │   └── utils/
│   └── manpower_distribution/  # Future
│
└── main.py                  # App registry
```

### Frontend Directory Structure
```
frontend/src/
├── core/                    # Shared UI
│   ├── components/layout/
│   ├── contexts/
│   └── api/client.ts
│
├── apps/                    # Individual apps
│   ├── po_automation/
│   │   ├── pages/
│   │   ├── components/
│   │   ├── api/
│   │   └── routes.tsx
│   └── manpower_distribution/  # Future
│
├── pages/                   # Platform pages
│   ├── LoginPage.tsx
│   └── DashboardPage.tsx    # App launcher
│
└── config/apps.ts           # App registry
```

### Router Organization
`backend/app/main.py`
```python
# Core routes
app.include_router(auth_router, prefix="/api/auth")

# App routes
app.include_router(extraction_router, prefix="/api/po-automation")
app.include_router(manpower_router, prefix="/api/manpower")
```

### Dashboard Page
`frontend/src/pages/DashboardPage.tsx`
- Show cards for each app user has access to
- Click to navigate to app

---

## Implementation Order

### Start with Phase 1 (Recommended)
1. Update `backend/app/config.py` with customer-aware methods
2. Update `lookup_service.py` with customer parameter
3. Update `po_checker.py` with customer parameter
4. Update `extraction.py` router with customer param
5. Test existing functionality still works
6. Test with `customer="emerson"` explicit param

### Then Phase 2
7. Create `backend/app/db/` directory and files
8. Set up Alembic migrations
9. Update auth router to save users to DB
10. Update JWT to include permissions
11. Test login creates user record

### Then Phase 3
12. Add auth dependencies
13. Update middleware for app access checks
14. Update frontend AuthContext
15. Test access control works

### Finally Phase 4
16. Create new directory structure
17. Move files to new locations
18. Update all imports
19. Create dashboard page
20. Test multi-app routing

---

## Verification Steps

After each phase:

1. **Run backend tests**: `cd backend && pytest`
2. **Run frontend**: `cd frontend && npm run dev`
3. **Test extraction flow**: Upload PDF, check PO, generate SO
4. **Check API manually**:
   - `GET /api/auth/me` returns user with permissions
   - `POST /api/extract-po?customer=emerson` works
5. **Verify Vercel deployment** (if applicable)

---

## Rollback Strategy

- Each phase maintains backward compatibility
- Feature flags can disable new functionality:
  - `ENABLE_DATABASE=false` - Skip DB writes
  - `ENABLE_PERMISSION_CHECKS=false` - Allow all access
- Keep pre-migration branch for emergency rollback
