# "Finally Learned" X Share Feature

## Overview
Add one-click X/Twitter sharing when users mark items as learned. Uses Twitter Web Intent (no API auth needed).

## Tweet Format
```
✅ Finally learned: {topic_header}
({N} days in queue)

{2-line summary snippet}

via Focus First
```

---

## Files to Create

### 1. `lib/share.ts` - Share utility (single source of truth)
```typescript
export interface ShareData {
  header: string
  summary: string
  createdAt: number
  learnedAt: number
  sourceUrl?: string | null
}

// Functions:
// - calculateDaysInQueue(createdAt, learnedAt) → number (min 1)
// - buildTweetText(data) → string (handles truncation to 280 chars)
// - buildTwitterIntentUrl(data) → string
// - shareToTwitter(data) → void (opens centered popup)
```

### 2. `components/ShareModal.tsx` - Post-learn share prompt
- Follows `AuthModal.tsx` pattern (framer-motion, backdrop, rounded-lg)
- Shows tweet preview
- Two buttons: "Skip" and "Share on X"
- Props: `isOpen`, `onClose`, `shareData`

---

## Files to Modify

### 1. `types/index.ts`
Add `createdAt` to `ArchiveItem`:
```typescript
export interface ArchiveItem {
  id: string
  header: string
  summary: string
  sourceUrl?: string | null
  learnedAt: number
  createdAt?: number  // NEW - for calculating days in queue
}
```

### 2. `app/page.tsx`
**Add state** (after line 20):
```typescript
const [isShareModalOpen, setIsShareModalOpen] = useState(false)
const [pendingShareData, setPendingShareData] = useState<ShareData | null>(null)
```

**Modify `handleMarkLearned`** (lines 146-169):
```typescript
const handleMarkLearned = useCallback(async () => {
  const learnedItem = queue[0]
  if (!learnedItem) return

  const learnedAt = Date.now()

  const archiveItem: ArchiveItem = {
    id: learnedItem.id,
    header: learnedItem.header,
    summary: learnedItem.summary,
    sourceUrl: learnedItem.sourceUrl,
    learnedAt,
    createdAt: learnedItem.createdAt,  // NEW: preserve for share
  }

  await addToArchive(archiveItem)
  await removeItem(learnedItem.id)

  // NEW: Show share modal
  setPendingShareData({
    header: learnedItem.header,
    summary: learnedItem.summary,
    createdAt: learnedItem.createdAt,
    learnedAt,
    sourceUrl: learnedItem.sourceUrl,
  })
  setIsShareModalOpen(true)

  // Existing architect logic...
}, [...])
```

**Add ShareModal to JSX** (after AuthModal):
```tsx
<ShareModal
  isOpen={isShareModalOpen}
  onClose={() => setIsShareModalOpen(false)}
  shareData={pendingShareData}
/>
```

### 3. `components/ArchiveDrawer.tsx`
Add share button next to "Re-queue":
```tsx
<div className="flex gap-3">
  <button onClick={() => shareToTwitter({...item})} className="text-xs text-faded hover:text-ink underline">
    Share
  </button>
  <button onClick={() => onRequeue(item)} className="text-xs text-faded hover:text-ink underline">
    Re-queue
  </button>
</div>
```

### 4. `hooks/useArchive.ts`
Update DB mapping to handle `createdAt`:
- Add to `DatabaseArchiveItem` interface
- Update `dbToApp()` and `appToDb()` functions

---

## Implementation Order

1. **`lib/share.ts`** - Core utility, no dependencies
2. **`types/index.ts`** - Add `createdAt` to `ArchiveItem`
3. **`hooks/useArchive.ts`** - Handle new field in DB operations
4. **`components/ShareModal.tsx`** - Create modal component
5. **`app/page.tsx`** - Integrate modal into mark-learned flow
6. **`components/ArchiveDrawer.tsx`** - Add share buttons

---

## Edge Cases

| Case | Solution |
|------|----------|
| Long header | Truncate to 100 chars with ellipsis |
| Long summary | Take first 2 lines, truncate to 120 chars |
| Learned same day | Show "1 day" minimum |
| Old archive items without `createdAt` | Fallback to `learnedAt` (shows "1 day") |
| Popup blocked | Falls back to new tab |

---

## Verification

1. Run `npm run dev`
2. Add item to queue, mark as learned
3. Verify ShareModal appears with correct preview
4. Click "Share on X" → Twitter popup opens with pre-filled tweet
5. Click "Skip" → Modal closes, next item shows
6. Open Archive → Click "Share" on any item → Twitter popup opens
7. Test with old archive items (no `createdAt`) → Should show "1 day"

---

## Key Files

- `app/page.tsx:146-169` - handleMarkLearned hook point
- `components/AuthModal.tsx` - Modal pattern reference
- `types/index.ts:41-47` - ArchiveItem type to extend
- `hooks/useArchive.ts` - DB operations to update
