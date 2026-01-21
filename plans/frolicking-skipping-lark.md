# Login Page - Fix Social Button Styling

## Issue
Social login buttons (Google, GitHub, Notion) have dark text on dark background, making them invisible. The "Last used" badge is also misaligned.

## Root Cause
The `socialButtonsBlockButton` element only sets background color. Clerk's social buttons need additional element targeting for:
- Button text color
- Icon button styling (GitHub, Notion icons without text)
- "Last used" badge positioning

## Fix
**File:** `app/sign-in/[[...sign-in]]/page.tsx`

Add these additional Clerk element styles:

```tsx
elements: {
  // ... existing styles ...

  // Social button text (fixes "Continue with Google" visibility)
  socialButtonsBlockButtonText: "text-gray-100",

  // Icon-only social buttons (GitHub, Notion)
  socialButtonsIconButton: "bg-gray-800 border border-gray-700 hover:bg-gray-700",

  // "Last used" badge styling
  badge: "bg-gray-700 text-gray-300",
}
```

## Files to Modify
| File | Change |
|------|--------|
| `app/sign-in/[[...sign-in]]/page.tsx` | Add social button text and badge styling |
