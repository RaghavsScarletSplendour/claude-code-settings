# Plan: Button Style Differentiation

## Goal
Create visual hierarchy and tie the top bar to the card design system.

## Files to Modify
1. `components/CategoryManager.tsx` (line 47) - Dropdown trigger
2. `app/gallery/page.tsx` (line 69) - Add Prompt button

## Changes

### 1. Category Dropdown → Match Card Style
**Current:** `border border-gray-700 rounded-md hover:bg-gray-800`
**New:** `bg-gray-800 border border-white/5 rounded-xl hover:bg-gray-700`

Uses same `bg-gray-800`, `border-white/5`, and rounded corners as cards.

### 2. Add Prompt Button → Subtle Solid Blue
**Current:** `bg-gray-800 text-gray-300 rounded-md hover:bg-gray-700 hover:text-white`
**New:** `bg-blue-600/80 text-white rounded-xl hover:bg-blue-600`

Matches border-radius with dropdown, uses subtle blue for primary action.
