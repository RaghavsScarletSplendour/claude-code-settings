# Fix: Landing Page Particle Animation Appears to Stop

## Problem
The floating text particles in the landing page hero animation stop moving shortly after page load. They animate initially but then appear static.

## Root Cause Analysis

**You've already fixed the React issue** - the refactoring to pass `mousePosRef` instead of `mouseX`/`mouseY` values was correct. Now `animate` is stable and the animation loop runs continuously.

**The real issue is particle physics reaching equilibrium.** Looking at `LensCanvas.tsx` lines 103-110:

```javascript
// Outside lens: gentle drift with return to base
particle.x += particle.velocity.x        // Constant velocity
particle.y += particle.velocity.y

// Slowly drift back toward base position
particle.x += (particle.baseX - particle.x) * 0.002   // Return force
particle.y += (particle.baseY - particle.y) * 0.002
```

**What happens:**
1. Each particle has a constant velocity (e.g., +0.3 pixels/frame)
2. A return force pulls the particle back toward its base position
3. The return force grows stronger as the particle moves away from base
4. Eventually: `velocity = return_force` → particle reaches **equilibrium**
5. At equilibrium, the particle appears stationary because forces balance

**Math:** If `velocity.x = 0.3` and return factor is `0.002`:
- Equilibrium distance = `0.3 / 0.002 = 150 pixels` from base
- Particles drift 150px from their starting position then stop

This is why particles move "a lot" at first (drifting toward equilibrium) then appear to stop (they've reached equilibrium).

## Solution

Add time-varying randomness to the velocity so particles never reach a stable equilibrium. Option A is simplest:

### Option A: Periodically randomize velocity direction (Recommended)

In the animation loop, occasionally flip velocity direction randomly:

```javascript
// Every ~120 frames (2 sec at 60fps), randomly flip velocity direction
if (Math.random() < 0.008) {  // ~0.8% chance per frame
  particle.velocity.x *= Math.random() < 0.5 ? -1 : 1
  particle.velocity.y *= Math.random() < 0.5 ? -1 : 1
}
```

### Option B: Add noise to velocity each frame

```javascript
particle.x += particle.velocity.x + (Math.random() - 0.5) * 0.1
particle.y += particle.velocity.y + (Math.random() - 0.5) * 0.1
```

### Option C: Remove the return-to-base force entirely

Simply remove lines 108-110. Particles would bounce off walls indefinitely.

## Recommended: Option A

It preserves the gentle "cloud" feel while ensuring continuous motion. Particles will never settle into a static equilibrium.

## Files to Modify
- `components/landing/LensCanvas.tsx` (lines 103-110, add randomness)

## Verification
1. Run `npm run dev`
2. Open landing page
3. Watch particles for 60+ seconds without moving mouse
4. Particles should continuously drift around, never fully stopping
