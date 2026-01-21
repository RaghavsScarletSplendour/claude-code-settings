# SO Generator Styling - Phase 7: Fix Missing Right Border on Column B

## Issue
- The RIGHT side of the Order Value cell (and likely other Column B cells) is missing its border
- `THIN_BORDER` is defined with all 4 sides, but the right border isn't rendering

## Investigation
The `write_table_cell()` method applies `THIN_BORDER` which has:
```python
THIN_BORDER = Border(
    left=Side(style='thin'),
    right=Side(style='thin'),
    top=Side(style='thin'),
    bottom=Side(style='thin')
)
```

This should apply all 4 borders. Possible causes:
1. Column C cells have no borders, possibly interfering with Column B's right edge
2. Some other code is overwriting the border

## Fix
Ensure borders are explicitly applied. Add empty bordered cells in Column C for the header table rows to reinforce the right edge of the table.

## Changes to `_write_header()`

After filling Column B cells, add Column C empty cells with left border only (to close off the table visually):

```python
# Add right edge of table (Column C with left border only)
LEFT_ONLY_BORDER = Border(left=Side(style='thin'))
for i in range(table_height):
    cell = writer.write(table_start_row + i, 3, "")
    cell.border = LEFT_ONLY_BORDER
```

Or alternatively, just write empty cells with left border in Column C to close the table edge.

## Files to Modify
- `backend/app/services/so_generator.py`

## Verification
1. Run extraction on a test PDF
2. Open generated SO file
3. Verify all cells in the header table (rows 1-6, columns A-B) have complete borders
4. Verify the right edge of the table is clearly visible
