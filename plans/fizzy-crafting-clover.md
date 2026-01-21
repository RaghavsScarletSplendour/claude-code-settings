# Fix: Premature "No prompts found" message in Semantic Search

## Problem
When using semantic search mode, the "No prompts found" message appears **immediately** while the user is still typing their first query, before the search has even executed. This gives users a bad signal.

## Root Cause
In `/app/search/page.tsx`:

1. Semantic search is **debounced by 1 second** (lines 92-100)
2. When user types, `searchQuery` is set immediately → `hasQuery` becomes `true`
3. But `loading` is still `false` (debounce hasn't fired yet)
4. `searchResults` is `[]` (initial empty state)
5. The render logic (lines 143-164) shows "No prompts found" when:
   - `loading === false` ✓
   - `hasQuery === true` ✓
   - `displayPrompts.length === 0` ✓

**Result:** "No prompts found" shows during the 1-second debounce delay, before any search runs.

## Solution
Add a `hasSearchedSemantic` state to track whether a semantic search has completed. Only show "No prompts found" for semantic mode after a search has actually been performed.

## Changes

### File: `/app/search/page.tsx`

1. **Add new state variable:**
   ```tsx
   const [hasSearchedSemantic, setHasSearchedSemantic] = useState(false);
   ```

2. **Set `hasSearchedSemantic = true` when semantic search completes** (in `semanticSearch` function, after setting results)

3. **Reset `hasSearchedSemantic = false` when:**
   - Mode changes to text (in `handleModeChange`)
   - Query is cleared

4. **Update render logic** - Only show "No prompts found" when:
   - Text mode: show immediately (current behavior - text search is instant)
   - Semantic mode: only show if `hasSearchedSemantic === true`

## Implementation Details

The condition for showing "no results" changes from:
```tsx
displayPrompts.length === 0
```

To:
```tsx
displayPrompts.length === 0 && (searchMode === "text" || hasSearchedSemantic)
```
