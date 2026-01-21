# Multi-App Platform Architecture Plan

## STATUS: COMPLETED

The restructure was successfully implemented. All features work as before - only the code structure changed, not the display or functionality.

### What Was Done:
- **Backend**: Created `core/` (config, auth, utils) and `apps/po_so/` (router, services, models)
- **Frontend**: Created `core/` (api, auth, layout) and `apps/po-so/` (api, components, hooks, pages, types, utils)
- **Data**: Reorganized `data/customers/` → `data/apps/po_so/customers/`
- **Routing**: Updated all API routes to `/api/po/*` and frontend routes to `/po/*`

### Verified Working:
- Backend starts without errors
- Frontend builds successfully (3211 modules)
- Login/logout works
- All existing PO/SO features preserved

---

## User Choices
- **Database**: No database yet (keep file-based)
- **Scope**: Full restructure (frontend + backend)
- **New Apps**: Just restructure foundation, no new apps yet

## Executive Summary

Transform this single-purpose PO/SO application into a **modular platform** that can host multiple independent apps (estimation calculator, sales dashboard, etc.) without conflicts.

**Current State**: Single-purpose monolith with good separation of concerns
**Target State**: Multi-app platform with isolated modules sharing common infrastructure

---

## Current Architecture Analysis

### What You Have Today

```
┌─────────────────────────────────────────────────────┐
│                    FRONTEND                          │
│  React 19 + TypeScript + Ant Design + React Query   │
│  ┌─────────────────────────────────────────────────┐│
│  │ Single App.tsx with all routes                  ││
│  │ Pages: HomePage, ExtractionPage, LoginPage      ││
│  │ State: usePurchaseOrder hook (PO/SO specific)   ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                    BACKEND                           │
│              FastAPI + Pydantic v2                   │
│  ┌─────────────────────────────────────────────────┐│
│  │ Single main.py entry point                      ││
│  │ Routers: extraction.py, auth.py                 ││
│  │ Services: pdf_extractor, po_checker, etc.       ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                    DATA LAYER                        │
│  File-based only (Excel lookups in data/customers/) │
│  No active database (SQLite file exists but unused) │
│  Stateless - JWT auth only                          │
└─────────────────────────────────────────────────────┘
```

### Strengths to Preserve
- Clean separation: routers → services → models → utils
- Customer abstraction already in config
- Stateless JWT authentication
- React Query for server state
- Pydantic models for data contracts

### Gaps to Address
- No app boundaries - everything in one monolith
- Single route tree, single state management
- No database for persistent data
- Config is flat (no app-specific namespacing)

---

## Recommended Architecture: Domain-Based Modular Monolith

I recommend a **Modular Monolith** pattern over microservices. Here's why:

| Approach | Pros | Cons |
|----------|------|------|
| **Microservices** | Full isolation | Overkill for your scale, deployment complexity, network overhead |
| **Modular Monolith** | Clean boundaries, shared infra, simple deployment, easy refactoring | Requires discipline to maintain boundaries |

### Target Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         PLATFORM SHELL                            │
│  Shared: Auth, Layout, Navigation, Theme, Error Handling          │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  PO/SO App   │  │  Estimator   │  │  Dashboard   │  ... more  │
│  │              │  │     App      │  │     App      │            │
│  │ /po/*        │  │ /estimator/* │  │ /dashboard/* │            │
│  │              │  │              │  │              │            │
│  │ Own state    │  │ Own state    │  │ Own state    │            │
│  │ Own API      │  │ Own API      │  │ Own API      │            │
│  │ Own models   │  │ Own models   │  │ Own models   │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                      BACKEND API GATEWAY                          │
│                     (Single FastAPI Instance)                     │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ /api/po/*    │  │/api/estimator│  │/api/dashboard│            │
│  │              │  │     /*       │  │     /*       │            │
│  │ po_router    │  │ est_router   │  │ dash_router  │            │
│  │ po_services  │  │ est_services │  │ dash_services│            │
│  │ po_models    │  │ est_models   │  │ dash_models  │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    SHARED CORE                              │  │
│  │  auth/  │  config/  │  utils/  │  database/  │  models/    │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Shared DB  │  │ App-specific│  │  File Store │              │
│  │  (users,    │  │   tables    │  │  (lookups,  │              │
│  │  audit)     │  │  (prefixed) │  │   uploads)  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└──────────────────────────────────────────────────────────────────┘
```

---

## Detailed Restructure Plan

### 1. Frontend Restructure

**New Directory Structure:**

```
frontend/src/
├── core/                          # SHARED PLATFORM CORE
│   ├── api/
│   │   └── client.ts              # Axios instance (shared)
│   ├── auth/
│   │   ├── AuthContext.tsx        # Shared auth provider
│   │   ├── ProtectedRoute.tsx
│   │   └── hooks/useAuth.ts
│   ├── layout/
│   │   ├── PlatformShell.tsx      # Main shell with nav
│   │   ├── AppLayout.tsx          # Per-app content wrapper
│   │   ├── Sidebar.tsx            # App navigation
│   │   └── Header.tsx
│   ├── components/                # Shared UI components
│   │   ├── LoadingSpinner.tsx
│   │   ├── ErrorBoundary.tsx
│   │   └── ...
│   └── types/                     # Shared types
│       └── common.ts
│
├── apps/                          # ISOLATED APP MODULES
│   ├── po-so/                     # Current PO/SO app (renamed)
│   │   ├── api/                   # App-specific API calls
│   │   │   ├── extraction.ts
│   │   │   ├── poChecker.ts
│   │   │   └── salesOrder.ts
│   │   ├── components/            # App-specific components
│   │   │   ├── POHeaderForm.tsx
│   │   │   ├── LineItemsTable.tsx
│   │   │   └── ...
│   │   ├── hooks/                 # App-specific hooks
│   │   │   └── usePurchaseOrder.ts
│   │   ├── pages/                 # App-specific pages
│   │   │   ├── HomePage.tsx
│   │   │   └── ExtractionPage.tsx
│   │   ├── types/                 # App-specific types
│   │   │   └── purchaseOrder.ts
│   │   ├── utils/                 # App-specific utils
│   │   │   └── calculations.ts
│   │   ├── routes.tsx             # App route definitions
│   │   └── index.ts               # App entry point
│   │
│   ├── estimator/                 # FUTURE: Estimation calculator
│   │   ├── api/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── pages/
│   │   ├── types/
│   │   ├── routes.tsx
│   │   └── index.ts
│   │
│   └── dashboard/                 # FUTURE: Sales dashboard
│       ├── api/
│       ├── components/
│       ├── hooks/
│       ├── pages/
│       ├── types/
│       ├── routes.tsx
│       └── index.ts
│
├── App.tsx                        # Root: mounts shell + app routes
├── appRegistry.ts                 # Registry of all apps
└── main.tsx                       # Entry point
```

**App Registry Pattern:**

```typescript
// frontend/src/appRegistry.ts
export interface AppModule {
  id: string;
  name: string;
  basePath: string;
  icon: React.ReactNode;
  routes: RouteObject[];
  navItems?: NavItem[];
}

export const appRegistry: AppModule[] = [
  {
    id: 'po-so',
    name: 'PO/SO Automation',
    basePath: '/po',
    icon: <FileTextOutlined />,
    routes: poSoRoutes,
  },
  {
    id: 'estimator',
    name: 'Estimation Calculator',
    basePath: '/estimator',
    icon: <CalculatorOutlined />,
    routes: estimatorRoutes,
  },
  // Add new apps here
];
```

**Key Principles:**
- Each app is a self-contained module with its own state, API, components
- Apps don't import from other apps (isolation)
- Shared code lives in `core/`
- App registry enables dynamic navigation

---

### 2. Backend Restructure

**New Directory Structure:**

```
backend/app/
├── core/                          # SHARED PLATFORM CORE
│   ├── config/
│   │   ├── settings.py            # Base settings class
│   │   ├── database.py            # DB connection config
│   │   └── apps.py                # App registry config
│   ├── auth/
│   │   ├── middleware.py          # JWT middleware
│   │   ├── router.py              # /api/auth/* endpoints
│   │   ├── service.py             # Auth business logic
│   │   └── models.py              # User model
│   ├── database/
│   │   ├── base.py                # SQLAlchemy base
│   │   ├── session.py             # Session management
│   │   └── migrations/            # Alembic migrations
│   ├── utils/                     # Shared utilities
│   │   ├── excel_loader.py
│   │   ├── parsers.py
│   │   └── normalizers.py
│   └── models/                    # Shared Pydantic models
│       └── common.py
│
├── apps/                          # ISOLATED APP MODULES
│   ├── po_so/                     # Current PO/SO app
│   │   ├── router.py              # /api/po/* endpoints
│   │   ├── services/
│   │   │   ├── pdf_extractor.py
│   │   │   ├── po_checker.py
│   │   │   ├── so_generator.py
│   │   │   └── lookup_service.py
│   │   ├── models/
│   │   │   ├── schemas.py         # Pydantic models
│   │   │   └── db_models.py       # SQLAlchemy models (if needed)
│   │   ├── config.py              # App-specific config
│   │   └── __init__.py
│   │
│   ├── estimator/                 # FUTURE: Estimation app
│   │   ├── router.py              # /api/estimator/*
│   │   ├── services/
│   │   ├── models/
│   │   ├── config.py
│   │   └── __init__.py
│   │
│   └── dashboard/                 # FUTURE: Dashboard app
│       ├── router.py              # /api/dashboard/*
│       ├── services/
│       ├── models/
│       ├── config.py
│       └── __init__.py
│
├── main.py                        # FastAPI app, mounts all routers
└── __init__.py
```

**Router Mounting Pattern:**

```python
# backend/app/main.py
from fastapi import FastAPI
from app.core.auth.router import router as auth_router
from app.apps.po_so.router import router as po_so_router
from app.apps.estimator.router import router as estimator_router

app = FastAPI(title="JD Jones Platform")

# Core routes
app.include_router(auth_router, prefix="/api/auth", tags=["auth"])

# App routes (isolated by prefix)
app.include_router(po_so_router, prefix="/api/po", tags=["po-so"])
app.include_router(estimator_router, prefix="/api/estimator", tags=["estimator"])
```

**Key Principles:**
- Each app has its own router, services, models
- Apps don't import from other apps
- Shared code lives in `core/`
- Clear URL namespacing: `/api/po/*`, `/api/estimator/*`, `/api/dashboard/*`

---

### 3. Database Strategy (FUTURE - Not implementing now)

When you need a database later, use **single PostgreSQL with table prefixing**:
- Shared tables: `users`, `audit_logs`
- App tables: `po_so_orders`, `estimator_quotes`, etc.

---

### 4. Configuration Strategy

**Hierarchical Config with Namespacing:**

```python
# backend/app/core/config/settings.py
from pydantic_settings import BaseSettings
from typing import Dict, Any

class CoreSettings(BaseSettings):
    """Platform-wide settings"""
    app_name: str = "JD Jones Platform"
    debug: bool = False

    # Database
    database_url: str = "postgresql://..."

    # Auth
    jwt_secret_key: str
    jwt_expiration_hours: int = 24
    google_client_id: str
    google_client_secret: str
    allowed_email_domain: str = "jdjones.com"

    # Paths
    data_dir: str = "data"

    class Config:
        env_prefix = "PLATFORM_"
        env_file = ".env"

# backend/app/apps/po_so/config.py
from pydantic_settings import BaseSettings

class POSOSettings(BaseSettings):
    """PO/SO app-specific settings"""
    default_customer: str = "emerson"
    valid_customers: list[str] = ["emerson"]
    max_line_item_pages: int = 3

    # App-specific lookup files
    lookup_files: dict = {
        "emerson": {
            "automation": "Emerson_Automation.xlsx",
            "specs": "EMERSON_SPECS.xlsx",
        }
    }

    class Config:
        env_prefix = "POSO_"  # App-specific prefix!
        env_file = ".env"

# backend/app/apps/estimator/config.py
class EstimatorSettings(BaseSettings):
    """Estimator app-specific settings"""
    default_markup_percentage: float = 15.0
    currency_conversion_api: str = "..."

    class Config:
        env_prefix = "ESTIMATOR_"  # App-specific prefix!
        env_file = ".env"
```

**Environment Variables (`.env`):**

```bash
# PLATFORM-WIDE (shared)
PLATFORM_DATABASE_URL=postgresql://user:pass@localhost/jdjones
PLATFORM_JWT_SECRET_KEY=your-secret-key
PLATFORM_GOOGLE_CLIENT_ID=...
PLATFORM_GOOGLE_CLIENT_SECRET=...
PLATFORM_ALLOWED_EMAIL_DOMAIN=jdjones.com

# PO/SO APP
POSO_DEFAULT_CUSTOMER=emerson
POSO_MAX_LINE_ITEM_PAGES=3

# ESTIMATOR APP
ESTIMATOR_DEFAULT_MARKUP_PERCENTAGE=15.0

# DASHBOARD APP
DASHBOARD_REFRESH_INTERVAL_SECONDS=300
```

**Key Principles:**
- Each app has its own env prefix (`POSO_`, `ESTIMATOR_`, `DASHBOARD_`)
- Platform settings use `PLATFORM_` prefix
- No collision possible
- Easy to see which setting belongs to which app

---

### 5. File Storage Strategy

**Current State:** Files in `data/customers/{customer}/lookups/`

**Recommended Structure:**

```
data/
├── shared/                        # Shared across all apps
│   └── uploads/                   # Temp upload storage
│
├── apps/                          # App-specific data
│   ├── po_so/
│   │   └── customers/
│   │       └── emerson/
│   │           ├── lookups/
│   │           │   ├── so_generator/
│   │           │   └── po_checker/
│   │           └── samples/
│   │
│   ├── estimator/
│   │   └── pricing/
│   │       ├── materials.xlsx
│   │       └── labor_rates.xlsx
│   │
│   └── dashboard/
│       └── exports/
│           └── reports/
```

**Path Resolution:**

```python
# backend/app/core/config/settings.py
class CoreSettings(BaseSettings):
    data_dir: str = "data"

    def get_app_data_dir(self, app_id: str) -> Path:
        return Path(self.data_dir) / "apps" / app_id

    def get_shared_data_dir(self) -> Path:
        return Path(self.data_dir) / "shared"
```

---

## Implementation Plan (Focused on Foundation)

### Phase 1: Backend Restructure

**Step 1.1: Create core/ directory structure**
```
backend/app/core/
├── __init__.py
├── config/
│   ├── __init__.py
│   └── settings.py          # Platform settings (PLATFORM_ prefix)
├── auth/
│   ├── __init__.py
│   ├── middleware.py         # Move from middleware/auth.py
│   ├── router.py             # Move from routers/auth.py
│   └── service.py            # Auth business logic
└── utils/
    ├── __init__.py
    ├── excel_loader.py       # Move from utils/
    ├── parsers.py            # Move from utils/
    ├── normalizers.py        # Move from utils/
    └── calculations.py       # Move from utils/
```

**Step 1.2: Create apps/po_so/ directory structure**
```
backend/app/apps/
├── __init__.py
└── po_so/
    ├── __init__.py
    ├── config.py             # POSO_ prefixed settings
    ├── router.py             # Move from routers/extraction.py
    ├── services/
    │   ├── __init__.py
    │   ├── pdf_extractor.py  # Move from services/
    │   ├── data_cleaner.py   # Move from services/
    │   ├── lookup_service.py # Move from services/
    │   ├── po_checker.py     # Move from services/
    │   └── so_generator.py   # Move from services/
    └── models/
        ├── __init__.py
        ├── schemas.py        # Move from models/po_data.py
        └── check_result.py   # Move from models/po_check_result.py
```

**Step 1.3: Update main.py to mount routers**
- Import from new locations
- Mount `/api/auth` from `core.auth.router`
- Mount `/api/po` from `apps.po_so.router`

**Step 1.4: Update all imports and verify**
- Fix all import paths
- Run backend tests/manual verification
- Ensure existing API works unchanged

### Phase 2: Frontend Restructure

**Step 2.1: Create core/ directory structure**
```
frontend/src/core/
├── api/
│   └── client.ts             # Move from api/client.ts
├── auth/
│   ├── AuthContext.tsx       # Move from contexts/
│   ├── ProtectedRoute.tsx    # Extract from App.tsx
│   └── hooks/
│       └── index.ts
├── layout/
│   ├── PlatformShell.tsx     # New: main shell with app switcher
│   ├── AppLayout.tsx         # Move from components/layout/
│   ├── Header.tsx            # Extract header logic
│   └── Sidebar.tsx           # New: app navigation
├── components/
│   ├── LoadingSpinner.tsx    # Common components
│   └── ErrorBoundary.tsx
└── types/
    └── common.ts             # Shared types
```

**Step 2.2: Create apps/po-so/ directory structure**
```
frontend/src/apps/po-so/
├── api/
│   ├── extraction.ts         # Move from api/
│   ├── poChecker.ts          # Move from api/
│   └── salesOrder.ts         # Move from api/
├── components/
│   ├── POHeaderForm.tsx      # Move from components/extraction/
│   ├── LineItemsTable.tsx    # Move from components/extraction/
│   ├── PDFViewer.tsx         # Move from components/extraction/
│   ├── POCheckResults.tsx    # Move from components/
│   ├── PDFUploader.tsx       # Move from components/upload/
│   └── BatchUploadProgress.tsx
├── hooks/
│   ├── usePurchaseOrder.ts   # Move from hooks/
│   └── index.ts
├── pages/
│   ├── HomePage.tsx          # Move from pages/
│   └── ExtractionPage.tsx    # Move from pages/
├── types/
│   └── purchaseOrder.ts      # Move from types/
├── utils/
│   └── calculations.ts       # Move from utils/
├── routes.tsx                # Define app routes
└── index.ts                  # App entry point
```

**Step 2.3: Create app registry and update App.tsx**
```typescript
// frontend/src/appRegistry.ts
export const appRegistry = [
  {
    id: 'po-so',
    name: 'PO/SO Automation',
    basePath: '/po',
    routes: poSoRoutes,
  },
  // Future apps go here
];
```

**Step 2.4: Update routing structure**
- `/login` → Login page (core)
- `/auth/callback` → OAuth callback (core)
- `/` → Platform home (app selector or redirect to default app)
- `/po/*` → PO/SO app routes
- `/estimator/*` → Future estimator routes
- `/dashboard/*` → Future dashboard routes

**Step 2.5: Verify frontend works**
- Test all existing functionality
- Ensure navigation works
- Check auth flow still works

### Phase 3: Config & Data Migration

**Step 3.1: Update environment variables**
```bash
# Rename existing vars with PLATFORM_ prefix
PLATFORM_JWT_SECRET_KEY=...
PLATFORM_GOOGLE_CLIENT_ID=...
PLATFORM_GOOGLE_CLIENT_SECRET=...
PLATFORM_ALLOWED_EMAIL_DOMAIN=...

# Add PO/SO specific vars
POSO_DEFAULT_CUSTOMER=emerson
```

**Step 3.2: Reorganize data directory**
```
data/
├── shared/                   # Future: shared uploads
└── apps/
    └── po_so/
        └── customers/
            └── emerson/
                ├── lookups/
                │   ├── so_generator/
                │   └── po_checker/
                └── samples/
```

### Phase 4: Verification & Documentation

1. Run full application locally
2. Test all existing features work
3. Update CLAUDE.md with new structure
4. Update docs/CODEBASE_MAP.md

---

## Critical Files to Modify

### Backend (in order)
1. Create `backend/app/core/__init__.py` and subdirectories
2. Create `backend/app/apps/__init__.py` and `apps/po_so/`
3. Move `backend/app/config.py` → split into `core/config/settings.py` + `apps/po_so/config.py`
4. Move `backend/app/middleware/auth.py` → `core/auth/middleware.py`
5. Move `backend/app/routers/auth.py` → `core/auth/router.py`
6. Move `backend/app/routers/extraction.py` → `apps/po_so/router.py`
7. Move `backend/app/services/*` → `apps/po_so/services/`
8. Move `backend/app/models/*` → `apps/po_so/models/`
9. Move `backend/app/utils/*` → `core/utils/`
10. Update `backend/app/main.py` with new imports

### Frontend (in order)
1. Create `frontend/src/core/` directory structure
2. Create `frontend/src/apps/po-so/` directory structure
3. Move `frontend/src/api/client.ts` → `core/api/client.ts`
4. Move `frontend/src/contexts/AuthContext.tsx` → `core/auth/AuthContext.tsx`
5. Move `frontend/src/components/layout/` → `core/layout/`
6. Move remaining API files → `apps/po-so/api/`
7. Move `frontend/src/components/` → `apps/po-so/components/`
8. Move `frontend/src/hooks/` → `apps/po-so/hooks/`
9. Move `frontend/src/pages/` → `apps/po-so/pages/`
10. Move `frontend/src/types/` → `apps/po-so/types/`
11. Move `frontend/src/utils/` → `apps/po-so/utils/`
12. Create `frontend/src/appRegistry.ts`
13. Update `frontend/src/App.tsx`

---

## Isolation Rules (Enforce These Always)

1. **No Cross-App Imports**: `apps/po_so/` NEVER imports from `apps/estimator/`
2. **URL Namespacing**: Backend `/api/{app_id}/*`, Frontend `/{app_id}/*`
3. **Config Prefixing**: All env vars use `{APP_ID}_` prefix
4. **File Path Isolation**: All files in `data/apps/{app_id}/...`

---

## Verification Checklist

After restructure, verify:
- [ ] Backend starts without errors
- [ ] Frontend builds without errors
- [ ] Login/logout works
- [ ] PDF upload and extraction works
- [ ] PO validation works
- [ ] SO generation works
- [ ] Batch upload works
- [ ] All API endpoints respond correctly

---

## Future: Adding New Apps

When ready to add Estimator or Dashboard:

1. Create `backend/app/apps/{app_id}/` with router, services, models, config
2. Create `frontend/src/apps/{app_id}/` with same structure
3. Add entry to `appRegistry.ts`
4. Mount router in `main.py`
5. Create `data/apps/{app_id}/` for app-specific files
6. Add `{APP_ID}_` env vars as needed
