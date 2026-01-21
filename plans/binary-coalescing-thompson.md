# Plan: Fix Search Input Text Color

## Overview
Add black text color to the search input so typed text is visible.

## Change Required

### File: `app/page.tsx` (line 58)

Add `text-gray-900` class to the search input className.

**Current:**
```
className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
```

**New:**
```
className="px-3 py-2 border border-gray-300 rounded-md text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
```

## Files to Modify
- `app/page.tsx` (line 58 only)
