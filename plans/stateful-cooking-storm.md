# Manual Override for SO Generation

## Problem
Currently, the "Generate This Sales Order" button is disabled when validation errors exist (`hasErrors`). The user wants to add a manual override option to generate SOs even when validation fails, since there can be edge cases that are too difficult to account for.

**Constraint:** Manual override should ONLY work for single SOs, NOT for batch generation.

## Current Behavior
- `ExtractionPage.tsx:207` - `hasErrors = checkResult !== null && !checkResult.passed`
- `ExtractionPage.tsx:428` - Button is disabled when `hasErrors` is true
- `ExtractionPage.tsx:445-449` - Shows helper text when errors exist

## Proposed Solution

**Simple approach:** Add a "Generate Anyway" link that appears below the disabled button when:
1. There are validation errors (`hasErrors === true`)
2. It's NOT a batch mode situation

### Implementation

**File: `frontend/src/pages/ExtractionPage.tsx`**

1. Add a Popconfirm wrapper for the override action (to confirm user intent)

2. Modify the bottom action section to add an override link:
   - Keep the primary "Generate This Sales Order" button disabled when errors exist
   - Add a small text link below it: "Generate anyway (bypass validation)"
   - This link only appears when `hasErrors && !isBatchMode`
   - Clicking shows a Popconfirm: "Are you sure? The generated SO may contain incorrect data."
   - On confirm, calls `handleGenerate()` directly

### Code Changes

```tsx
// Add Popconfirm import at top
import { ..., Popconfirm } from 'antd';

// In the action section (around line 445):
{hasErrors && !isBatchMode && (
  <Popconfirm
    title="Bypass validation?"
    description="The generated SO may contain incorrect data. Are you sure?"
    onConfirm={handleGenerate}
    okText="Generate Anyway"
    cancelText="Cancel"
  >
    <Typography.Link style={{ fontSize: 12 }}>
      Generate anyway (bypass validation)
    </Typography.Link>
  </Popconfirm>
)}
```

## Why This Approach

1. **Minimal code change** - Only ~10 lines added
2. **Explicit user action** - User must click AND confirm, reducing accidental overrides
3. **Visual hierarchy** - Primary button stays disabled (encouraging proper validation), override is secondary
4. **Batch exclusion** - Simple conditional `!isBatchMode` handles the single-only requirement
5. **No backend changes** - Backend already accepts any PO data regardless of validation

## Verification

1. Upload a PDF that has validation errors
2. Verify the "Generate anyway" link appears below the disabled button
3. Click the link and verify confirmation dialog appears
4. Confirm and verify SO is generated successfully
5. Test batch mode - verify the "Generate anyway" link does NOT appear
