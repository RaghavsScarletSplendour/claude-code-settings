# Fix: SearchModeToggle Pill Width for Semantic

## Issue
The blue pill width is fixed at `calc(50% - 12px)` for both modes, but "Semantic" is longer than "Text" so it gets cut short when selected.

## Fix
Use dynamic width based on which mode is selected:

**File:** `/components/search/SearchModeToggle.tsx` (line 19)

```tsx
// Before
width: "calc(50% - 12px)",

// After - different width for each mode
width: mode === "text" ? "calc(40%)" : "calc(58%)",
```

- Text mode: ~40% width (shorter word)
- Semantic mode: ~58% width (longer word)
