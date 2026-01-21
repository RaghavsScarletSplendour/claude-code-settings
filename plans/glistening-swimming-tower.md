# Plan: Test Background Image

## Goal
Add the background image from `backgroundimages/image.png` to test how the app looks with a background instead of pure black. Make components semi-transparent so the background shows through.

## Changes

### 1. `app/layout.tsx` (line 33)
Change main wrapper from:
```tsx
className="flex min-h-screen bg-black"
```
To:
```tsx
className="flex min-h-screen bg-cover bg-center bg-fixed"
style={{ backgroundImage: "url('/backgroundimages/image.png')" }}
```

### 2. `components/Sidebar.tsx` (line 46)
Change sidebar from `bg-black` to `bg-black/80` for 80% opacity (semi-transparent)

### 3. Check for card/content components
Look for any Card components or content areas that need transparency adjustments

## Files to Modify
- `app/layout.tsx` - add background image
- `components/Sidebar.tsx` - make semi-transparent
