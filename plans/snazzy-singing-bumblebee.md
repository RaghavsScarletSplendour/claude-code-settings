# Display "Not Found" Errors Differently

## Problem

When a part number isn't found in the price list, the error shows:
- Expected: "(in price list)"
- Actual: "GH17201X012"

This is confusing because it's not a real comparison - the part doesn't exist in the lookup.

---

## Solution

In the frontend's "Expected vs Actual" column, detect "not found" errors and display them as a simple "Not Found" tag instead of the comparison format.

---

## Changes

**File:** `frontend/src/components/POCheckResults.tsx`

In the comparison column render (around line 233), add a check:

```tsx
// Detect "not found" errors (expected starts with "(in")
const isNotFound = record.expected.startsWith('(in');

if (isNotFound) {
  return (
    <Tag color="orange">Not Found</Tag>
  );
}

// Otherwise show normal comparison...
```

---

## Verification

1. Build compiles without errors
2. Upload a PO with a part number not in the price list
3. Error should show "Not Found" tag instead of "(in price list) vs GH17201X012"
4. Normal comparison errors (price mismatch, rev mismatch) still show expected vs actual
