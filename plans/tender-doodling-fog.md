# Plan: Remove Text from Landing Page Instruction Hint

## Goal
Remove the "Move cursor to reveal" / "Tap to continue" text from the landing page animation, keeping only the mouse animation icon.

## File to Modify
- `components/landing/HeroAnimation.tsx`

## Code Change
Remove the `<span>` element (lines 212-214) while keeping the mouse animation:

```typescript
// Before (lines 211-222)
<div className="flex flex-col items-center gap-2 text-faded">
  <span className="text-xs font-mono">
    {isTouchDevice ? 'Tap to continue' : 'Move cursor to reveal'}
  </span>
  <motion.div
    animate={{ y: [0, 8, 0] }}
    ...
  </motion.div>
</div>

// After
<div className="flex flex-col items-center gap-2 text-faded">
  <motion.div
    animate={{ y: [0, 8, 0] }}
    ...
  </motion.div>
</div>
```

## Verification
1. Run `npm run dev` and visit `http://localhost:3000`
2. Confirm only the animated mouse icon appears at the bottom - no text
3. Check on mobile viewport to ensure "Tap to continue" text is also removed
