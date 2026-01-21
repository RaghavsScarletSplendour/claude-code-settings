# 8pt Grid System Implementation Plan

## Overview
Update the UI to follow the 8pt grid system where all spacing uses multiples of 8 (8, 16, 24, 32, 48, 64px).

## Key Changes

### 1. Sidebar Width
**File:** `components/Sidebar.tsx`
- Current: `w-fit pr-6` (variable) / `w-16` (64px collapsed)
- Change to: `w-60` (240px fixed) when expanded, keep `w-16` (64px) collapsed
- Fix: `gap-5` (20px) → `gap-6` (24px)
- Fix: `px-3` (12px) → `px-4` (16px)
- Fix: `p-1.5` (6px) → `p-2` (8px)

### 2. Main Container Padding
**File:** `app/layout.tsx`
- Current: `p-8` (32px)
- Change to: `p-16` (64px)

### 3. Grid Gap - No Change Needed
**File:** `components/PromptGallery.tsx`
- Current: `gap-6` (24px) ✓ Already compliant

## Implementation Steps

- [ ] **Step 1:** Update `components/Sidebar.tsx`
  - Change expanded width from `w-fit pr-6` to `w-60`
  - Change nav gap from `gap-5` to `gap-6`
  - Change link padding from `px-3` to `px-4`
  - Change collapsed padding from `p-1.5` to `p-2`
  - Change bottom `px-3` to `px-4`

- [ ] **Step 2:** Update `app/layout.tsx`
  - Change main padding from `p-8` to `p-16`

## Files to Modify
1. `components/Sidebar.tsx` - sidebar width & spacing
2. `app/layout.tsx` - container padding
