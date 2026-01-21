# Fix Item Number Extraction for Dash-Separated Format

## Problem
PO 4781070508 has item code "24000-633" but the system extracts only "633".

## Root Cause
The regex pattern `ITEM_NO_REV_PATTERN` in `backend/app/utils/parsers.py` uses `[A-Z0-9]+` which excludes the dash character. When parsing "24000-633 Rev # B", the regex skips "24000-" and matches starting from "633".

## Solution
Modify the regex pattern to handle dash-separated item numbers.

### File to Modify
- `backend/app/utils/parsers.py` (lines 9-12)

### Change
```python
# BEFORE
ITEM_NO_REV_PATTERN = re.compile(
    r"([A-Z0-9]+X?\d*)\s+Rev\s*#?\s*([A-Z0-9]+)",
    re.IGNORECASE
)

# AFTER
ITEM_NO_REV_PATTERN = re.compile(
    r"([A-Z0-9]+(?:-[A-Z0-9]+)?X?\d*)\s+Rev\s*#?\s*([A-Z0-9]+)",
    re.IGNORECASE
)
```

The addition of `(?:-[A-Z0-9]+)?` allows an optional dash followed by more alphanumerics, capturing formats like:
- "24000-633" → captures full "24000-633"
- "1J5047X0062" → still works (no dash)
- "GH11505X012" → still works (no dash)

### Also update fallback pattern (line 72)
```python
# BEFORE
item_match = re.search(r"([A-Z0-9]+X\d+)", text, re.IGNORECASE)

# AFTER
item_match = re.search(r"([A-Z0-9]+(?:-[A-Z0-9]+)?X?\d*)", text, re.IGNORECASE)
```

## Verification
1. Run existing tests: `pytest backend/tests/test_pdf_extractor.py -v`
2. Test with PO 4781070508 PDF to confirm "24000-633" is extracted correctly
3. Test with existing PO formats to ensure no regression
