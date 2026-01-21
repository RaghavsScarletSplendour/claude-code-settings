# Plan: Unique Colors for Categories

## Overview
Add unique, aesthetic colors to each category. Colors are auto-assigned from a curated palette based on category ID (deterministic - same category always gets same color).

---

## Implementation Steps

### Step 1: Create Color Config & Utility
**Create:** `lib/categoryColors.ts`

```typescript
// Curated aesthetic color palette (Tailwind classes)
const CATEGORY_COLORS = [
  { bg: 'bg-rose-100', text: 'text-rose-700' },
  { bg: 'bg-orange-100', text: 'text-orange-700' },
  { bg: 'bg-amber-100', text: 'text-amber-700' },
  { bg: 'bg-emerald-100', text: 'text-emerald-700' },
  { bg: 'bg-teal-100', text: 'text-teal-700' },
  { bg: 'bg-cyan-100', text: 'text-cyan-700' },
  { bg: 'bg-sky-100', text: 'text-sky-700' },
  { bg: 'bg-indigo-100', text: 'text-indigo-700' },
  { bg: 'bg-violet-100', text: 'text-violet-700' },
  { bg: 'bg-fuchsia-100', text: 'text-fuchsia-700' },
  { bg: 'bg-pink-100', text: 'text-pink-700' },
  { bg: 'bg-slate-100', text: 'text-slate-700' },
];

// Hash function to get consistent color index from category ID
export function getCategoryColor(categoryId: string): { bg: string; text: string }
```

To change colors later: just edit the `CATEGORY_COLORS` array.

### Step 2: Create CategoryBadge Component
**Create:** `components/ui/CategoryBadge.tsx`

Reusable badge component that:
- Takes `categoryId` and `name` props
- Uses `getCategoryColor()` to apply the right colors
- Renders consistent badge styling (`text-xs px-2 py-1 rounded`)

### Step 3: Create CategoryColorDot Component
**Create:** `components/ui/CategoryColorDot.tsx`

Small colored circle for dropdowns:
- Takes `categoryId` prop
- Uses `getCategoryColor()` for background color
- Renders as small circle (e.g., `w-3 h-3 rounded-full`)

### Step 4: Update PromptCard
**Modify:** `components/PromptCard.tsx`

Replace inline badge code (lines ~121-128) with `<CategoryBadge />` component.

### Step 5: Update PromptDetailModal
**Modify:** `components/PromptDetailModal.tsx`

Replace inline badge code (lines ~227-232) with `<CategoryBadge />` component.

### Step 6: Add Color Dots to CategoryManager
**Modify:** `components/CategoryManager.tsx`

Add `<CategoryColorDot />` next to category names in:
- The dropdown filter options
- The manage categories modal list

### Step 7: Add Color Dots to CategorySelect
**Modify:** `components/ui/CategorySelect.tsx`

Add color indicators to the select dropdown options (if possible with native select, or note limitation).

---

## Files Summary

| File | Action |
|------|--------|
| `lib/categoryColors.ts` | CREATE |
| `components/ui/CategoryBadge.tsx` | CREATE |
| `components/ui/CategoryColorDot.tsx` | CREATE |
| `components/PromptCard.tsx` | MODIFY |
| `components/PromptDetailModal.tsx` | MODIFY |
| `components/CategoryManager.tsx` | MODIFY |
| `components/ui/CategorySelect.tsx` | MODIFY (if feasible) |

---

## DRY Principle
- Single color palette definition in `lib/categoryColors.ts`
- Single `getCategoryColor()` function used everywhere
- Reusable `CategoryBadge` and `CategoryColorDot` components
- No color logic duplicated across components
