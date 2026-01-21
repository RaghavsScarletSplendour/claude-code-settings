# Plan: Bold Header Table and Footer Signature

## Summary
Add bold formatting to all cells in the header table (rows 1-6) and "For J.D.Jones and Co. Pvt. Ltd." in footer.

## File to Modify
`backend/app/services/so_generator.py`

## Changes

### 1. Header table cells (lines 242-269 in `_write_header`)
Add `.font = Font(bold=True)` after each `write_table_cell` call:
- Row 1: Work order No., Date
- Row 2: Buyer name
- Rows 3+: Address lines, Order Value, GST, PAN

### 2. Footer signature (line 506 in `_write_footer`)
Add `.font = Font(bold=True)` to "For J.D.Jones and Co. Pvt. Ltd."

## Verification
1. Generate test SO
2. Verify header table cells are bold
3. Verify "For J.D.Jones and Co. Pvt. Ltd." is bold
