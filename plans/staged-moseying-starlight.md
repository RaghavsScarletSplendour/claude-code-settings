# Plan: Unified Design System - Glowing Node Aesthetic

## Overview
Align all UI elements with the particle system's "Glowing Node" aesthetic for a cohesive, professional look.

## Design Tokens

### Border Radius System
- **Cards**: `rounded-2xl` (16px) - unchanged
- **Buttons/Dropdowns/Inputs**: `rounded-lg` (8px) - currently `rounded-md` (6px)
- **Sidebar active state**: `rounded-lg` (8px) - match buttons

### Color Palette
- **Primary Action**: Teal/Cyan glow (`bg-cyan-600` with `shadow-[0_0_15px_rgba(6,182,212,0.3)]`)
- **Secondary UI Border**: `border-white/10` (match cards)
- **Backgrounds**: `bg-[#0d1117]` for dropdowns/inputs (match cards)

---

## Tasks

### 1. Update Button Component
**File:** `components/ui/Button.tsx`

**Changes:**
- Primary variant: `bg-blue-600` → `bg-cyan-600 hover:bg-cyan-500`
- Add glow effect: `shadow-[0_0_15px_rgba(6,182,212,0.3)]`
- Border radius: `rounded-md` → `rounded-lg`

### 2. Update Dropdown Component
**File:** `components/ui/Dropdown.tsx`

**Changes:**
- Background: `bg-gray-800` → `bg-[#0d1117]`
- Border: `border-gray-700` → `border-white/10`
- Border radius: `rounded-md` → `rounded-lg`

### 3. Update Form Inputs
**File:** `components/ui/FormInput.tsx`

**Changes:**
- Background: `bg-gray-800` → `bg-[#0d1117]`
- Border: `border-gray-700` → `border-white/10`
- Border radius: Add `rounded-lg`
- Focus ring: `focus:ring-blue-500` → `focus:ring-cyan-500`

### 4. Update CategoryManager Dropdown
**File:** `components/CategoryManager.tsx`

**Changes:**
- Dropdown trigger: Match button styling with `rounded-lg`
- Dropdown menu: `bg-gray-800 border-gray-700` → `bg-[#0d1117] border-white/10 rounded-lg`

### 5. Update Search Input
**File:** `app/search/page.tsx`

**Changes:**
- Background: `bg-gray-800` → `bg-[#0d1117]`
- Border: `border-gray-700` → `border-white/10`
- Border radius: `rounded-md` → `rounded-lg`
- Focus ring: `focus:ring-blue-500` → `focus:ring-cyan-500`

### 6. Update Sidebar Active State
**File:** `components/Sidebar.tsx`

**Changes:**
- Hover/active: `rounded-md` → `rounded-lg`

### 7. Darken Category Badge Colors
**File:** `lib/categoryColors.ts`

**Changes:**
- Reduce brightness: `/10` opacity backgrounds → `/15` for slightly more visible but still subtle
- This creates a more "dark amber background with light amber text" look as requested

---

## Files to Modify

| File | Key Changes |
|------|-------------|
| `components/ui/Button.tsx` | Cyan primary, glow effect, rounded-lg |
| `components/ui/Dropdown.tsx` | Card-style bg/border, rounded-lg |
| `components/ui/FormInput.tsx` | Card-style bg/border, cyan focus, rounded-lg |
| `components/CategoryManager.tsx` | Card-style dropdown, rounded-lg |
| `app/search/page.tsx` | Card-style input, rounded-lg |
| `components/Sidebar.tsx` | rounded-lg for consistency |
| `lib/categoryColors.ts` | Slightly more visible badge backgrounds |

## Visual Result
- Primary buttons glow like the particle nodes (cyan/teal)
- All secondary UI matches the card aesthetic (dark bg + white/10 border)
- Consistent 8px radius on interactive elements (half of card's 16px)
- Category badges remain subtle but slightly more visible
