# Fix Vercel Build Error - Unused Imports

## Problem
Vercel build failing with TypeScript errors for unused imports:
```
src/hooks/usePurchaseOrder.ts(2,15): error TS6196: 'PurchaseOrder' is declared but never used.
src/pages/HomePage.tsx(6,35): error TS6196: 'PurchaseOrder' is declared but never used.
```

## Root Cause
After the multi-PO refactoring, these files import `PurchaseOrder` but no longer use it directly (they now use `MultiPurchaseOrder`).

## Fix

### File 1: `frontend/src/hooks/usePurchaseOrder.ts`
- Remove `PurchaseOrder` from the import statement on line 2
- Keep only: `POHeader`, `POLineItem`, `MultiPurchaseOrder`

### File 2: `frontend/src/pages/HomePage.tsx`
- Remove `PurchaseOrder` from the import statement on line 6
- Keep only: `MultiPurchaseOrder`

## Verification
- Run `npx tsc --noEmit` to verify no TypeScript errors
- Commit and push to trigger Vercel rebuild
