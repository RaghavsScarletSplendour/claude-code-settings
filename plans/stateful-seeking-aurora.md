# Fix: Manual Override Button Not Showing

## Problem
The "Generate anyway (bypass validation)" link doesn't appear when uploading files (single or batch) with validation errors.

## Root Cause
In `frontend/src/pages/ExtractionPage.tsx` line 450, the manual override link has an incorrect condition:
```typescript
{hasErrors && !isBatchMode && (
```

The `!isBatchMode` condition was unnecessarily hiding the link in batch mode. Since the manual override generates SO for only the **currently selected PO**, it should work in both single and batch modes.

## Solution
Remove the `!isBatchMode` condition so the manual override appears whenever there are validation errors.

**File:** `frontend/src/pages/ExtractionPage.tsx`

Change line 450 from:
```typescript
{hasErrors && !isBatchMode && (
```

To:
```typescript
{hasErrors && (
```

## Files to Modify
- `frontend/src/pages/ExtractionPage.tsx` - Line 450: remove `&& !isBatchMode`

## Verification
1. Upload a single PDF with validation errors → manual override link should appear
2. Upload multiple PDFs (batch mode) with validation errors → manual override link should appear
3. Click the link → confirm Popconfirm dialog appears
4. Click "Generate Anyway" → confirm SO generates for the currently selected PO only
5. Switch to different PO in batch → confirm manual override still works
