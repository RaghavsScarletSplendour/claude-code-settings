# Plan: Hide Empty Columns in Excel Export

## Summary
When exporting data to Excel, hide columns that have no data across ALL exported results. If even one result has data for a column, that column will be included.

## Code Principles Applied

- **DRY**: Column filtering logic in one reusable function, not duplicated
- **KISS**: Simple single-pass algorithm, minimal changes to existing files
- **YAGNI**: Only implementing what's needed - no extra config options or UI

## Files to Modify

| File | Action | Lines Changed |
|------|--------|---------------|
| `backend/utils/export/columnFilter.js` | CREATE | ~20 lines |
| `backend/utils/export/excelTemplate.js` | MODIFY | ~3 lines (add parameter) |
| `backend/utils/export/excelWriter.js` | MODIFY | ~3 lines (add parameter) |
| `backend/utils/export/exportIndex.js` | MODIFY | ~5 lines (call filter) |

## Implementation Steps

### Step 1: Create Column Filter Utility
**File**: `backend/utils/export/columnFilter.js` (NEW)

Simple function `getColumnsWithData(resultsArray)`:
- Loop through results, track which columns have data using a Set
- Return filtered `EXPORT_COLUMN_MAP` with only populated columns
- Preserves original column order

### Step 2: Modify Excel Template
**File**: `backend/utils/export/excelTemplate.js`

- Add `columnMap` parameter with default `EXPORT_COLUMN_MAP`
- Replace direct usage with parameter (2 places: column count, header loop)

### Step 3: Modify Excel Writer
**File**: `backend/utils/export/excelWriter.js`

- Add `columnMap` parameter with default `EXPORT_COLUMN_MAP`
- Replace direct usage with parameter (1 place: data loop)

### Step 4: Update Export Index
**File**: `backend/utils/export/exportIndex.js`

- Import and call `getColumnsWithData()` before template creation
- Pass result to `loadExcelTemplate()` and `writeResultToExcel()`

## Verification

1. Export multiple products - verify unused columns hidden
2. Export single calculation - verify only populated columns appear
3. Export with all fields - verify no columns hidden
4. Verify header styling and product colors still work
