# Plan: Add Rounded Corners to All Sharp-Cornered Elements

## Tech Stack Analysis
- **Framework**: Next.js 14.2.15 with React 18
- **Styling**: Tailwind CSS 3.4.14
- **Animation**: Framer Motion 12.x
- **Language**: TypeScript

## Summary of Findings

All borders in this application currently have sharp/rectangular corners (no `border-radius` or Tailwind `rounded-*` classes). The app uses a consistent design pattern with `border-2 border-ink` for all bordered elements.

---

## All Instances Requiring Rounded Corners

### 1. Global CSS Button Classes (`/app/globals.css`)

**File**: `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/app/globals.css`

#### `.btn-process` (Lines 18-26)
```css
.btn-process {
  @apply inline-flex items-center justify-center;
  @apply px-6 py-3 border-2 border-ink bg-ink text-paper;
  /* ... no rounded class */
}
```
**Fix**: Add `rounded-lg` or similar to the @apply directives.

#### `.btn-learned` (Lines 28-35)
```css
.btn-learned {
  @apply inline-flex items-center justify-center;
  @apply px-6 py-3 border-2 border-ink bg-paper text-ink;
  /* ... no rounded class */
}
```
**Fix**: Add `rounded-lg` or similar to the @apply directives.

---

### 2. DumpForm Component (`/components/DumpForm.tsx`)

**File**: `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/components/DumpForm.tsx`

#### Collapsed State Button (Lines 29-35)
```tsx
<button
  onClick={onToggle}
  className="w-full border-2 border-ink bg-paper p-4 text-left text-faded hover:text-ink hover:bg-paper transition-colors"
>
```
**Fix**: Add `rounded-lg` class.

#### Expanded Form Container (Line 39)
```tsx
<div className="border-2 border-ink bg-paper p-8">
```
**Fix**: Add `rounded-lg` class.

#### Textarea Input (Lines 47-56)
```tsx
<textarea
  className="w-full bg-transparent border-2 border-ink p-4 font-mono text-ink placeholder:text-faded resize-none focus:outline-none disabled:opacity-50"
/>
```
**Fix**: Add `rounded-lg` class.

---

### 3. FocusCard Component (`/components/FocusCard.tsx`)

**File**: `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/components/FocusCard.tsx`

#### Main Card Container (Lines 24-27)
```tsx
<div
  className={`border-2 border-ink bg-paper p-8 transition-all duration-300 ${
    isMarking ? 'opacity-0 translate-y-4' : ''
  }`}
>
```
**Fix**: Add `rounded-lg` class.

#### Complexity Badge (Line 32)
```tsx
<span className="inline-block px-2 py-1 text-xs border border-faded text-faded">
```
**Fix**: Add `rounded` or `rounded-md` class (smaller element, smaller radius).

#### Mark as Learned Button (Lines 68-72)
Uses `.btn-learned` class - will be fixed via globals.css change.

---

### 4. ArchiveDrawer Component (`/components/ArchiveDrawer.tsx`)

**File**: `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/components/ArchiveDrawer.tsx`

#### Drawer Panel (Lines 54-59)
```tsx
className="fixed right-0 top-0 h-full w-80 bg-paper border-l-2 border-ink z-50 flex flex-col"
```
**Note**: This is a side drawer - only has left border. May want `rounded-l-lg` for the left edge, or leave as-is since it's a full-height drawer.

#### Archive Item Cards (Lines 84-87)
```tsx
<div
  key={item.id}
  className="border-2 border-ink bg-paper p-4"
>
```
**Fix**: Add `rounded-lg` class.

---

### 5. Main Page Component (`/app/page.tsx`)

**File**: `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/app/page.tsx`

#### Error Display Container (Lines 278-287)
```tsx
<div className="border-2 border-ink bg-paper p-4 text-center">
```
**Fix**: Add `rounded-lg` class.

#### Empty State Container (Lines 326-334)
```tsx
<motion.div
  key="empty"
  className="border-2 border-ink bg-paper p-8 text-center"
>
```
**Fix**: Add `rounded-lg` class.

---

## Recommended Border Radius Values

For consistency across the app, I recommend:

| Element Type | Tailwind Class | CSS Value |
|-------------|---------------|-----------|
| Cards/Containers | `rounded-lg` | 0.5rem (8px) |
| Buttons | `rounded-lg` | 0.5rem (8px) |
| Input Fields | `rounded-lg` | 0.5rem (8px) |
| Small Badges | `rounded-md` | 0.375rem (6px) |
| Full-height Drawers | Leave as-is or `rounded-l-lg` | - |

---

## Implementation Approach

### Option A: Add rounded classes directly to each component
Modify each file individually, adding the appropriate `rounded-*` class.

### Option B: Create reusable CSS component classes
Add global component classes in `globals.css`:
```css
.card {
  @apply border-2 border-ink bg-paper rounded-lg;
}

.input-field {
  @apply border-2 border-ink rounded-lg;
}
```

### Option C: Extend Tailwind config with custom border-radius defaults
Not recommended as it would affect all Tailwind rounded utilities.

---

## Files to Modify (Summary)

1. `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/app/globals.css`
   - `.btn-process` - add `rounded-lg`
   - `.btn-learned` - add `rounded-lg`

2. `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/components/DumpForm.tsx`
   - Line 31: collapsed button - add `rounded-lg`
   - Line 39: form container - add `rounded-lg`
   - Line 55: textarea - add `rounded-lg`

3. `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/components/FocusCard.tsx`
   - Line 25: main card container - add `rounded-lg`
   - Line 32: complexity badge - add `rounded-md`

4. `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/components/ArchiveDrawer.tsx`
   - Line 86: archive item cards - add `rounded-lg`
   - (Optional) Line 59: drawer panel - add `rounded-l-lg`

5. `/Users/raghavbajoria/Desktop/Coding Projects/focused-information/app/page.tsx`
   - Line 279: error display - add `rounded-lg`
   - Line 331: empty state - add `rounded-lg`

---

## Total Changes Required

- **5 files** to modify
- **10-11 elements** that need rounded corners
- Estimated time: 10-15 minutes for implementation
