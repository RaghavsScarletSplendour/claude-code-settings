# Archive & Progress Log Implementation Plan

## Summary
Add a slide-out drawer showing learned items with the ability to re-queue items for review. Minimal design - just header + date learned.

## Requirements
- Slide-out drawer (not separate route)
- Simple list: header + date learned
- Re-queue button on each item
- No stats (streak, totals, etc.)
- Show last 50 items, most recent first

## Files to Modify

### 1. `types/index.ts`
Add `ArchiveItem` type:
```typescript
export interface ArchiveItem {
  id: string
  header: string
  summary: string
  sourceUrl?: string | null
  learnedAt: number  // timestamp when marked learned
}
```

### 2. `components/ArchiveDrawer.tsx` (NEW)
Create slide-out drawer component:
- Takes `isOpen`, `onClose`, `items`, `onRequeue` props
- Slides in from right side
- Shows list of archive items (header + relative date)
- Each item has "Re-queue" button
- Framer Motion for slide animation
- Matches existing typewriter/workorder aesthetic

### 3. `app/page.tsx`
Modifications:
- Add `HISTORY_KEY = 'focus-first-history'` constant
- Add `archive` state: `useState<ArchiveItem[]>([])`
- Add `isArchiveOpen` state for drawer visibility
- Load archive from localStorage on mount
- Modify `handleMarkLearned`:
  - Before removing from queue, save to archive with `learnedAt` timestamp
  - Save archive to localStorage
- Add `handleRequeue` function:
  - Remove item from archive
  - Add back to queue (re-summarize via API or use existing data)
- Add Archive toggle button (icon in corner)
- Render `ArchiveDrawer` component

## Implementation Steps

1. **Add ArchiveItem type** to `types/index.ts`

2. **Create ArchiveDrawer component** with:
   - Overlay backdrop (click to close)
   - Slide-in panel from right
   - Header with "Archive" title and close button
   - Scrollable list of items
   - Each item shows: header, relative date ("2 days ago"), Re-queue button
   - Empty state: "No learned items yet"

3. **Update page.tsx**:
   - Add archive state and localStorage persistence
   - Modify `handleMarkLearned` to archive items
   - Add `handleRequeue` to move items back to queue
   - Add archive toggle button (small "Archive" link or icon)
   - Render ArchiveDrawer

4. **Style to match existing aesthetic**:
   - `border-2 border-ink bg-paper` for drawer
   - `text-faded` for dates
   - `btn-learned` style for re-queue buttons

## UI Placement
- Archive toggle: Small icon/link in top-right corner of main page
- Drawer: Slides in from right, ~320px wide
- Backdrop: Semi-transparent overlay when drawer is open
