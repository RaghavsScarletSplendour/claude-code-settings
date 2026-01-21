# Remove Dashboard ("Home") Page

## Summary
Remove the Dashboard page (`/dashboard`) from the app and update the sidebar to only show Gallery and Search tabs. Users will land on `/gallery` after signing in.

## Files to Modify

### 1. Delete Dashboard Page
- **File:** `app/(app)/dashboard/page.tsx`
- **Action:** Delete this file entirely

### 2. Update Sidebar Navigation
- **File:** `components/Sidebar.tsx` (line 19)
- **Action:** Remove the "Home" nav item that links to `/dashboard`

### 3. Update Sign-In Redirect
- **File:** `app/sign-in/[[...sign-in]]/page.tsx` (line 9)
- **Action:** Change `forceRedirectUrl="/dashboard"` to `forceRedirectUrl="/gallery"`

### 4. Update Beta Access Redirect
- **File:** `app/beta-access/page.tsx` (line 33)
- **Action:** Change `router.push("/dashboard")` to `router.push("/gallery")`
