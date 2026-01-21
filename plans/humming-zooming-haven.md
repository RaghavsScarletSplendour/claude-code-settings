# Bug Fix: FocusCard not showing next item after marking learned

## Problem
When marking a task as learned, the next task in queue doesn't appear (invisible).

## Root Cause
Missing `key` prop on FocusCard component in `app/page.tsx:142`. React reuses the component instance, preserving `isMarking: true` state which applies `opacity-0` to the new item.

## Fix
Add `key={currentItem.id}` to FocusCard:

```tsx
// app/page.tsx line 142
<FocusCard key={currentItem.id} item={currentItem} onMarkLearned={handleMarkLearned} />
```

## File to Modify
- `app/page.tsx` - line 142
