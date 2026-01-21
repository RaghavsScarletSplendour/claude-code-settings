# PO Checker UI Improvements Plan

## Overview
Enhance the PO Checker UI with 3 improvements:
1. Auto-run check on page load
2. Summary dashboard showing validation status at a glance
3. Better error display with improved grouping and visuals

## Implementation

### 1. Auto-run Check on Load
**File:** `frontend/src/pages/ExtractionPage.tsx`

- Add `useEffect` hook to trigger `handleCheckPO()` when component mounts
- Show loading spinner while check runs
- Keep manual "Check PO" button for re-running after edits

```tsx
useEffect(() => {
  handleCheckPO();
}, []); // Run once on mount
```

### 2. Summary Dashboard
**File:** `frontend/src/components/POCheckResults.tsx`

Add a visual summary section above the detailed results:
- **5 check type cards** in a row showing pass/fail status with icons
- **Progress indicator** showing X/5 checks passed
- **Location badge** (Chennai/International) prominently displayed

Layout:
```
┌─────────────────────────────────────────────────────────┐
│  [Progress: 3/5 Passed]         [Location: Chennai]     │
├─────────┬─────────┬─────────┬─────────┬─────────────────┤
│  Price  │ Drawing │   FMS   │  Spec   │  Transit Time   │
│   ✓     │    ✗    │    ✓    │    ✗    │       ✓         │
│ 0 errors│ 2 errors│ 0 errors│ 1 error │    0 errors     │
└─────────┴─────────┴─────────┴─────────┴─────────────────┘
```

Components to use:
- `Row`/`Col` for layout
- `Card` with `size="small"` for each check type
- `Progress` component for overall status
- `Tag` for location
- Icons: `CheckCircleOutlined` (green), `CloseCircleOutlined` (red)

### 3. Better Error Display
**File:** `frontend/src/components/POCheckResults.tsx`

Improvements:
- **Color-coded severity**: Use consistent colors per check type
- **Clickable line numbers**: Help user navigate to the issue
- **Expected vs Actual side-by-side**: Clearer comparison view
- **Error count badges**: Show count per section header
- **Empty state**: Message when no errors for a check type

Update the table columns:
```tsx
const columns = [
  { title: 'Line', dataIndex: 'line_number', width: 60 },
  { title: 'Field', dataIndex: 'field', width: 100 },
  {
    title: 'Expected → Actual',
    render: (_, record) => (
      <Space>
        <Text code type="success">{record.expected}</Text>
        <span>→</span>
        <Text code type="danger">{record.actual}</Text>
      </Space>
    )
  },
  { title: 'Message', dataIndex: 'message' },
];
```

## Files to Modify

| File | Changes |
|------|---------|
| `frontend/src/pages/ExtractionPage.tsx` | Add useEffect for auto-run |
| `frontend/src/components/POCheckResults.tsx` | Add dashboard + improve error display |

## Verification

1. Start frontend dev server: `cd frontend && npm run dev`
2. Upload a sample PO PDF
3. Verify:
   - Check runs automatically on extraction page load
   - Summary dashboard shows 5 check cards with pass/fail icons
   - Error details show expected→actual comparison
   - Re-running "Check PO" button updates results
