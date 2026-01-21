# Fix: Batch Upload Single File Page Reset Bug

## Problem
After uploading a single PO file via batch upload and clicking "View Results", the page shows "Loaded 1 file(s) with 1 PO(s)" but immediately resets to the upload screen instead of navigating to the extraction page.

## Root Cause
In `frontend/src/hooks/usePurchaseOrder.ts`:

1. **Line 22**: `isBatchMode` checks `batchResults.length > 1` (not `>= 1`)
2. **Line 73-81**: `loadFromBatch` sets `multiPO` to `null`
3. **Line 25-33**: The `po` memo returns `null` when `isBatchMode` is false AND `multiPO` is null

When uploading 1 file:
- `batchResults.length === 1` -> `isBatchMode = false`
- `loadFromBatch` clears `multiPO = null`
- `po` memo falls through to legacy path, finds `multiPO === null`, returns `null`
- App.tsx redirects to "/" when `po` is `null`

## Solution
Change line 22 in `usePurchaseOrder.ts`:

```diff
- const isBatchMode = batchResults.length > 1;
+ const isBatchMode = batchResults.length > 0;
```

This ensures that when `loadFromBatch` is used, the hook reads from `batchResults` regardless of how many files were uploaded.

## Files to Modify
- `frontend/src/hooks/usePurchaseOrder.ts` (line 22)

## Verification
1. Run the dev server: `npm run dev` in frontend
2. Upload a single PDF file
3. Wait for processing to complete
4. Click "View Results"
5. Verify the extraction page loads correctly with the PO data
6. Also test with 2+ files to ensure batch mode still works
