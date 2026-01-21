# Hero Animation Fix: RevealCard Not Visible

## Problem
The RevealCard is not showing because the `LensCanvas` fills the entire canvas with an **opaque background** (`#F3F0E9`) on every frame, completely covering the card layer underneath.

## Root Cause
In `LensCanvas.tsx` line 81-83:
```javascript
// Clear canvas - THIS IS THE PROBLEM
ctx.fillStyle = '#F3F0E9'
ctx.fillRect(0, 0, width, height)
```

This makes the canvas 100% opaque, blocking the RevealCard at z-0.

## Solution
Make the canvas **transparent** so the RevealCard can show through:
1. Use `clearRect()` instead of `fillRect()` to clear with transparency
2. Only draw particles (no background fill)
3. The particles themselves create the "noise" layer, and the empty space reveals the card

---

## File to Modify

### `components/landing/LensCanvas.tsx`

**Change line 81-83 from:**
```javascript
// Clear canvas
ctx.fillStyle = '#F3F0E9'
ctx.fillRect(0, 0, width, height)
```

**To:**
```javascript
// Clear canvas with transparency
ctx.clearRect(0, 0, width, height)
```

---

## Verification

1. Run `npm run dev`, visit `http://localhost:3000`
2. Move mouse around hero section
3. Particles should part to form empty circle around cursor
4. **RevealCard should now be visible** within the cleared circle
