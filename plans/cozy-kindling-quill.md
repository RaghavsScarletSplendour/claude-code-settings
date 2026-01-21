# User Authentication with Clerk - Implementation Plan

## Overview
Use **Clerk** for authentication instead of building from scratch.
- Clerk handles: signup, login, OAuth (Google, GitHub), session management, UI components
- We just integrate it into our app

---

## Frontend Changes (Clerk handles most of it)

### Step 1: Install Clerk
```bash
cd frontend
npm install @clerk/nextjs
```

### Step 2: Add Clerk environment variables
**File**: `frontend/.env.local`

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
```

### Step 3: Wrap app with ClerkProvider
**File**: `frontend/src/app/layout.tsx`

```tsx
import { ClerkProvider } from '@clerk/nextjs'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>...</html>
    </ClerkProvider>
  )
}
```

### Step 4: Add Clerk middleware
**File**: `frontend/src/middleware.ts`

```tsx
import { clerkMiddleware } from '@clerk/nextjs/server'

export default clerkMiddleware()

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
}
```

### Step 5: Create sign-in page
**File**: `frontend/src/app/sign-in/[[...sign-in]]/page.tsx`

```tsx
import { SignIn } from '@clerk/nextjs'

export default function SignInPage() {
  return <SignIn />
}
```

### Step 6: Create sign-up page
**File**: `frontend/src/app/sign-up/[[...sign-up]]/page.tsx`

```tsx
import { SignUp } from '@clerk/nextjs'

export default function SignUpPage() {
  return <SignUp />
}
```

### Step 7: Update Sidebar with user info
**File**: `frontend/src/components/Sidebar.tsx`

Replace "Guest" section with Clerk's `<UserButton />` component.

### Step 8: Get user ID in API calls
**File**: `frontend/src/lib/api.ts`

Use `auth()` from Clerk to get the user's JWT token and pass it to the backend.

---

## Backend Changes

### Step 9: Install Clerk SDK
```bash
pip install clerk-backend-api
```
Or verify JWT manually with PyJWT.

### Step 10: Add Clerk config
**File**: `backend/app/config.py`

Add:
- `CLERK_SECRET_KEY`
- `CLERK_PUBLISHABLE_KEY` (optional)

### Step 11: Create auth dependency
**File**: `backend/app/dependencies.py`

Add `get_current_user()` that:
- Extracts JWT from Authorization header
- Verifies it using Clerk's JWKS endpoint
- Returns user ID (Clerk's `sub` claim)

### Step 12: Create User model
**File**: `backend/app/models/user.py`

Simple model to store Clerk user ID and cache user info:
```python
class User(Base):
    id: UUID
    clerk_id: str (unique)  # Clerk's user ID
    email: str
    name: str
    created_at: datetime
```

### Step 13: Add user_id to Prompt model
**File**: `backend/app/models/prompt.py`

Add `user_id` foreign key linking prompts to users.

### Step 14: Create migration
**File**: `backend/alembic/versions/002_add_users.py`

- Create users table
- Add user_id to prompts

### Step 15: Update prompts API
**File**: `backend/app/api/v1/prompts.py`

- Require authentication
- Filter prompts by current user
- Auto-assign user_id on create

---

## Files Summary

| Category | Files |
|----------|-------|
| Frontend packages | Install `@clerk/nextjs` |
| Frontend layout | `layout.tsx` - wrap with ClerkProvider |
| Frontend middleware | `middleware.ts` - protect routes |
| Frontend pages | `sign-in/page.tsx`, `sign-up/page.tsx` |
| Frontend components | `Sidebar.tsx` - add UserButton |
| Backend config | `config.py` - add CLERK_SECRET_KEY |
| Backend auth | `dependencies.py` - verify Clerk JWT |
| Backend models | `user.py` (new), `prompt.py` (add user_id) |
| Migration | `002_add_users.py` |

---

## Clerk Dashboard Setup

1. Create account at clerk.com
2. Create new application
3. Enable Google and GitHub OAuth in "Social Connections"
4. Copy API keys to `.env.local` and `.env`

---

## Benefits of Clerk
- Pre-built UI components (SignIn, SignUp, UserButton)
- Handles OAuth complexity
- Session management built-in
- Webhooks for user events
- Much less code to maintain
