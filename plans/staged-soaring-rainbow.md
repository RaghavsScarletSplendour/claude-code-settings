# Plan: Increase Button Text Sizes

## Changes
Make the Archive button, Sign in/Sign out button, and user email text 2 font sizes bigger (to match "X more in signal").

## File to Modify
- `app/page.tsx`

## Implementation

### 1. Auth controls wrapper (line 259)
**Before:**
```tsx
<div className="text-xs">
```

**After:**
```tsx
<div className="text-base">
```

This affects: user email, Sign out button, Sign in to sync button

### 2. Archive button (line 287)
**Before:**
```tsx
className="text-xs text-faded hover:text-ink transition-colors underline underline-offset-2"
```

**After:**
```tsx
className="text-base text-faded hover:text-ink transition-colors underline underline-offset-2"
```

## Verification
Run `npm run dev` and verify the Archive, Sign in/Sign out, and email text are larger on the main page.
