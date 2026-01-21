# Fix "Get Started" Button Click Blocking

## Problem
The "Get Started" button on the landing page cannot be clicked because the `LensCanvas` component's canvas element is layered on top (z-10) and intercepts all pointer events.

## Root Cause
In `components/landing/LensCanvas.tsx`, the canvas element:
- Has `z-10` positioning (above RevealCard at z-0)
- Covers the entire hero section (`absolute inset-0 w-full h-full`)
- Missing `pointer-events: none` - blocks all mouse clicks

## Fix Required

### File: `components/landing/LensCanvas.tsx`

Add `pointerEvents: 'none'` to the canvas style so clicks pass through to elements below.

**Before (line ~190):**
```tsx
<canvas
  ref={canvasRef}
  className="absolute inset-0 w-full h-full z-10"
  style={{ touchAction: 'none' }}
/>
```

**After:**
```tsx
<canvas
  ref={canvasRef}
  className="absolute inset-0 w-full h-full z-10"
  style={{ touchAction: 'none', pointerEvents: 'none' }}
/>
```

The canvas will still animate properly (it reads mouse position from `mousePosRef`) but won't block clicks meant for interactive elements below.

## Verification
1. Visit landing page at `http://localhost:3002`
2. Move cursor to reveal the card with particles
3. Click "Get Started" button
4. Should navigate to `/app`
