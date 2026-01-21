# Plan: Update PromptCard Styling

## Overview
Update card design with modern 2025 aesthetic - subtle borders, larger radius, refined shadows.

## File to Modify
- `components/PromptCard.tsx`

## Changes

### Current
```tsx
className="bg-gray-900 border border-gray-700 rounded-lg p-4 shadow-sm hover:shadow-md ..."
```

### New
```tsx
className="bg-gray-900 border border-white/5 rounded-2xl p-4 shadow-md hover:shadow-lg ..."
```

| Property | Before | After |
|----------|--------|-------|
| Border | `border-gray-700` | `border-white/5` (nearly invisible) |
| Radius | `rounded-lg` (8px) | `rounded-2xl` (16px) |
| Shadow | `shadow-sm` | `shadow-md` (subtle drop shadow) |
| Hover | `hover:shadow-md` | `hover:shadow-lg` |

Note: Using Tailwind equivalents:
- `border-white/5` = `rgba(255,255,255,0.05)` (for dark mode)
- `rounded-2xl` = 16px
- `shadow-md` ≈ the specified box-shadow
