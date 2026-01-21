# Plan: Make Ship Date and Receive Date Editable in Line Items Table

## Summary
Add editable DatePicker fields for `req_ship_date` and `req_rec_date` in the LineItemsTable component so users can adjust transit times after PDF extraction.

## Current State
- `LineItemsTable.tsx` (line 58-63): Ship Date column only displays value with `formatDate(value)` - not editable
- Receive Date (`req_rec_date`) is not even shown in the table
- Transit time validation requires `req_rec_date - req_ship_date >= 14 days` (international)

## Changes Required

### File: `frontend/src/components/extraction/LineItemsTable.tsx`

1. **Add imports** (line 1):
   ```typescript
   import { Table, Input, InputNumber, Typography, Tag, Tooltip, DatePicker } from 'antd';
   import dayjs from 'dayjs';
   ```

2. **Make Ship Date editable** (lines 58-63):
   Replace display-only render with DatePicker:
   ```typescript
   {
     title: 'Ship Date',
     dataIndex: 'req_ship_date',
     width: 120,
     render: (value, _record, index) => (
       <DatePicker
         size="small"
         value={value ? dayjs(value) : null}
         onChange={(date) =>
           onUpdate(index, { req_ship_date: date ? date.format('YYYY-MM-DD') : null })
         }
         style={{ width: '100%' }}
       />
     ),
   },
   ```

3. **Add Receive Date column** (after Ship Date):
   ```typescript
   {
     title: 'Rec Date',
     dataIndex: 'req_rec_date',
     width: 120,
     render: (value, _record, index) => (
       <DatePicker
         size="small"
         value={value ? dayjs(value) : null}
         onChange={(date) =>
           onUpdate(index, { req_rec_date: date ? date.format('YYYY-MM-DD') : null })
         }
         style={{ width: '100%' }}
       />
     ),
   },
   ```

4. **Adjust table scroll width** (line 148):
   Change `scroll={{ x: 1200 }}` to `scroll={{ x: 1320 }}` to accommodate the new column.

## Verification
1. Upload a PDF and navigate to the Line Items tab
2. Verify Ship Date and Receive Date columns show DatePickers
3. Edit the dates and confirm changes persist in the data
4. Run PO Check to verify transit time validation uses updated dates
