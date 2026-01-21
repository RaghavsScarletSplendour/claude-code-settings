# Fix: Particle System Black Screen on Login

## Problem Summary
The particle UI shows a black screen most times after login, requiring a page reload to display properly.

## Root Causes Identified

### 1. Duplicate ParticlesBackground Instances (PRIMARY)
- `app/layout.tsx:33` renders `<ParticlesBackground />` (60 particles)
- `app/sign-in/[[...sign-in]]/page.tsx:9` renders `<ParticlesBackground particleCount={25} />`
- `app/beta-access/page.tsx:43` renders `<ParticlesBackground particleCount={25} />`
- All three use same `id="tsparticles"` and share a singleton engine
- Creates conflict when navigating between pages

### 2. Missing useEffect Cleanup
- `components/ParticlesBackground.tsx:15-21` has no cleanup
- Can cause state updates on unmounted components
- Engine may be left in corrupted state during navigation

### 3. Invalid Hex Color
- `components/ParticlesBackground.tsx:31` has `"#00001"` (5 chars instead of 6)
- May cause parsing issues

## Implementation Steps

1. [ ] Remove `ParticlesBackground` from `app/sign-in/[[...sign-in]]/page.tsx`
   - Delete import on line 4
   - Delete component on line 9

2. [ ] Remove `ParticlesBackground` from `app/beta-access/page.tsx`
   - Delete import on line 5
   - Delete component on line 43

3. [ ] Fix hex color in `components/ParticlesBackground.tsx:31`
   - Change `"#00001"` to `"#000000"`

4. [ ] Add useEffect cleanup to `components/ParticlesBackground.tsx`:
   ```typescript
   useEffect(() => {
     let mounted = true;
     initParticlesEngine(async (engine) => {
       await loadSlim(engine);
     }).then(() => {
       if (mounted) setInit(true);
     });
     return () => { mounted = false; };
   }, []);
   ```

5. [ ] Test login flow multiple times to verify fix

## Files to Modify
- `components/ParticlesBackground.tsx` (fix color + add cleanup)
- `app/sign-in/[[...sign-in]]/page.tsx` (remove duplicate)
- `app/beta-access/page.tsx` (remove duplicate)
