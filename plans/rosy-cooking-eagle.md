# Plan: Eliminate Lens Reveal Latency (Zero Latency via Refs + CSS Variables)

## Problem
~50ms delay from CSS transition + React state update cycle

## Solution
Bypass React render cycle by using refs and CSS custom properties.

## Implementation

### Step 1: Replace mousePos state with a ref
```typescript
// Replace: const [mousePos, setMousePos] = useState({ x: 0, y: 0 })
// With:
const mousePosRef = useRef({ x: 0, y: 0 })
```

### Step 2: Create ref for the clip-path container
```typescript
const clipContainerRef = useRef<HTMLDivElement>(null)
```

### Step 3: Update handleMouseMove to set CSS variables directly
```typescript
const handleMouseMove = useCallback((e: React.MouseEvent) => {
  if (isTouchDevice) return
  const container = containerRef.current
  if (!container) return

  const rect = container.getBoundingClientRect()
  const x = e.clientX - rect.left
  const y = e.clientY - rect.top

  // Update ref (for LensCanvas)
  mousePosRef.current = { x, y }

  // Update CSS variables directly (for clip-path) - no React render needed
  if (clipContainerRef.current) {
    clipContainerRef.current.style.setProperty('--mx', `${x}px`)
    clipContainerRef.current.style.setProperty('--my', `${y}px`)
  }
}, [isTouchDevice])
```

### Step 4: Update clip-path div to use CSS variables
```tsx
<div
  ref={clipContainerRef}
  className="absolute inset-0 flex items-center justify-center z-0 px-4"
  style={{
    '--mx': '50%',
    '--my': '50%',
    clipPath: `circle(${lensRadius}px at var(--mx) var(--my))`,
  } as React.CSSProperties}
>
```

### Step 5: Pass ref to LensCanvas instead of values
Modify LensCanvas to accept a `mousePosRef` prop and read from it in the animation loop.

### Step 6: Update auto-animation for touch devices
Update the touch device animation to also set CSS variables directly.

## Files to Modify
- `components/landing/HeroAnimation.tsx` - main changes
- `components/landing/LensCanvas.tsx` - accept ref prop

## Verification
1. Run `npm run dev`
2. Visit `http://localhost:3000`
3. Move cursor rapidly - card reveal should track cursor instantly
