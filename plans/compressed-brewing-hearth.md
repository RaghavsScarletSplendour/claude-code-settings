# Plan: Create Blank Landing Page with Internal Route Configuration

## Overview
Create a blank landing page at the root route (`/`) and move the existing app functionality to `/app`. Configure routes internally in the code.

## Files to Modify/Create

| File | Action |
|------|--------|
| `app/app/page.tsx` | Create - Move existing app functionality here |
| `app/page.tsx` | Modify - Replace with blank landing page |
| `lib/routes.ts` | Create - Internal route configuration |
| `app/auth/callback/route.ts` | Modify - Update redirect to `/app` |

## Implementation Steps

### 1. Create `app/app/page.tsx`
- Copy entire contents from current `app/page.tsx`
- No changes needed to the copied code

### 2. Update `app/page.tsx` (Blank Landing)
```tsx
export default function LandingPage() {
  return null;
}
```

### 3. Create `lib/routes.ts`
```typescript
export const routes = {
  landing: '/',
  app: '/app',
} as const;

export type AppRoute = (typeof routes)[keyof typeof routes];
```

### 4. Update `app/auth/callback/route.ts`
- Change redirect from `/` to `/app` after successful auth

## Verification
1. `npm run dev`
2. Visit `http://localhost:3000/` → blank page
3. Visit `http://localhost:3000/app` → existing app functionality
4. Test auth flow → should redirect to `/app`
