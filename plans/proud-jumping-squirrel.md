# PO Checker Architecture Plan

## Executive Summary

This document captures architectural decisions for integrating a PO Checker into the existing SO Automation system, ensuring no duplication of PDF extraction and maintaining pipeline flexibility.

---

## Current State Analysis

### Multi-Customer Support

**Verdict: Currently Emerson-only, refactoring needed for multi-customer**

| Component | Emerson Coupling | Files Affected |
|-----------|------------------|----------------|
| Config paths | HIGH - hardcoded "emerson" | `backend/app/config.py` (lines 49, 53) |
| PDF Extractor | HIGH - 2-row table format | `backend/app/services/pdf_extractor.py` |
| Lookup Service | HIGH - FMS regex, filenames | `backend/app/services/lookup_service.py` |
| SO Generator | MEDIUM - FMS grouping | `backend/app/services/so_generator.py` |
| API/Frontend | LOW - just labels | Easy to change |

**Recommendation:** Stay single-customer for now. Multi-customer refactor is a separate initiative.

---

### Data Flow (No Duplication)

Current extraction happens **once**:
```
PDF → /api/extract-po → PurchaseOrder JSON → User edits → /api/generate-so
```

PO Checker will reuse the same `PurchaseOrder` object - no re-extraction needed.

---

## Agreed Architecture Decisions

### 1. Pipeline Choice: After Extraction
- Single upload flow
- User sees extracted data first
- Then chooses: "Quick SO" or "Full PO Check"

### 2. Error Handling: Block Until Fixed
- If PO Checker finds errors, user CANNOT proceed to SO generation
- Must resolve all errors first
- Clear error display with actionable messages

### 3. Validation Rules: DEFINED

**Chennai vs International Detection:**
- If `ship_to_address` contains "Chennai" or "India" → MSN Chennai → Use INR Price List
- Otherwise → International → Use USD Price List

---

## 5 Validation Checks

### Check 1: Price Validation
- **Source:** `line_item.item_no` (Part Number) and `line_item.unit_price`
- **Lookup:** Master Price List (INR for Chennai, USD for International)
  - Column B = Part Number
  - Column I = Price
- **Logic:** Look up part number in Col B, compare PO price with Col I price
- **Flag if:** Prices don't match

### Check 2: Drawing Revision Validation
- **Source:** `line_item.additional_specs` → Extract drawing number (first word before "Rev #")
  - Format: `18B0262 Rev # A: ENGINEERING DRAWING`
  - Drawing No = `18B0262`, Rev = `A`
- **Lookup:** "Latest Drawings" sheet (Col A = Drawing No, Col B = Rev)
- **Logic:** Find drawing number, compare revision
- **Flag if:** Revision doesn't match
- **Note:** Some items don't have drawings - skip those

### Check 3: FMS Revision Validation
- **Source:** `line_item.fms_code` and `line_item.fms_rev`
  - Example: `FMS17F46`, Rev `W`
- **Lookup:** "Latest FMS" sheet (Col A = Spec No, Col B = Rev)
- **Logic:** Find FMS code, compare revision
- **Flag if:** Revision doesn't match
- **Note:** Some products have material descriptions instead of FMS codes (e.g., "25% EG Carbon-Filled PTFE")
- **Normalization:** Lowercase both sides, strip spaces for comparison

### Check 4: Specification Revision Validation
- **Source:** `line_item.additional_specs` → Extract spec references (different from drawing)
  - Format: `DS39 Rev # G: O-RING GROOVES...`
- **Lookup:** "SPECIFICATIONS" sheet (Col A = Spec, Col B = Rev)
- **Logic:** Find spec, compare revision
- **Flag if:** Revision doesn't match
- **Note:** Not all items have specifications - skip those

### Check 5: Transit Time Validation
- **Source:** `line_item.req_ship_date` and `line_item.req_rec_date`
- **Rule:**
  - Chennai: `req_rec_date - req_ship_date` must be ≥ 8 days
  - International: `req_rec_date - req_ship_date` must be ≥ 14 days
- **Flag if:** Transit time is LESS than minimum required

---

## Data Normalization Requirements

For robust matching, normalize before comparison:
1. **Lowercase** both PO data and Excel data
2. **Strip whitespace** from both ends
3. **Handle Rev format variations:** "Rev # A", "Rev-A", "Rev A", "REV # A" → normalize to just the letter
4. **Handle FMS variations:** Some items have material names instead of FMS codes

---

## Proposed Pipeline Flow

```
                        ┌──────────────────┐
                        │   Upload PDF     │
                        │   (HomePage)     │
                        └────────┬─────────┘
                                 ↓
                        ┌──────────────────┐
                        │   Extract PO     │  ← Happens ONCE
                        │  /api/extract-po │
                        └────────┬─────────┘
                                 ↓
                        ┌──────────────────┐
                        │  ExtractionPage  │
                        │  (Review Data)   │
                        └────────┬─────────┘
                                 ↓
                    ┌────────────┴────────────┐
                    ↓                         ↓
           [Quick SO Button]         [Full Check Button]
                    ↓                         ↓
           ┌────────────────┐        ┌────────────────┐
           │  Generate SO   │        │   PO Checker   │
           │ /api/generate  │        │  /api/check-po │
           └────────────────┘        └───────┬────────┘
                                             ↓
                                    ┌────────────────┐
                                    │ Errors Found?  │
                                    └───────┬────────┘
                                      ╱           ╲
                                   YES             NO
                                    ↓              ↓
                           ┌──────────────┐  ┌──────────────┐
                           │ Show Errors  │  │ Generate SO  │
                           │ (BLOCKED)    │  │ (Proceed)    │
                           └──────────────┘  └──────────────┘
```

---

## Implementation Plan

### Phase 1: Backend - Data Model
1. Create `backend/app/models/po_check_result.py`:
   ```python
   class POCheckError:
       line_number: int
       check_type: str  # "price", "drawing_rev", "fms_rev", "spec_rev", "transit_time"
       field: str       # e.g., "unit_price", "drawing_rev"
       expected: str    # Value from master file
       actual: str      # Value from PO
       message: str     # Human-readable error

   class POCheckResult:
       passed: bool
       errors: list[POCheckError]
       is_chennai: bool
   ```

### Phase 2: Backend - PO Checker Service
1. Create `backend/app/services/po_checker.py`:
   - `__init__()`: Load all 3 Excel files into memory
   - `_is_chennai(po)`: Check ship_to_address for "Chennai" or "India"
   - `_normalize(text)`: Lowercase, strip whitespace
   - `_extract_rev(text)`: Extract just the revision letter from "Rev # A" etc.
   - `check_prices(po, is_chennai)`: Validate prices against INR/USD list
   - `check_drawing_revisions(po)`: Validate drawing revisions
   - `check_fms_revisions(po)`: Validate FMS revisions
   - `check_spec_revisions(po)`: Validate specification revisions
   - `check_transit_times(po, is_chennai)`: Validate ship/receive date gaps
   - `check(po) -> POCheckResult`: Run all checks, aggregate errors

### Phase 3: Backend - API Endpoint
1. Add to `backend/app/routers/extraction.py`:
   ```python
   @router.post("/check-po", response_model=POCheckResult)
   async def check_purchase_order(po: PurchaseOrder):
       checker = POChecker()
       return checker.check(po)
   ```

### Phase 4: Frontend - API Client
1. Create `frontend/src/api/poChecker.ts`:
   ```typescript
   export const checkPO = async (po: PurchaseOrder): Promise<POCheckResult>
   ```

### Phase 5: Frontend - UI Components
1. Modify `frontend/src/pages/ExtractionPage.tsx`:
   - Add "Check PO" button next to "Generate SO"
   - Add state for check results
   - Disable "Generate SO" if check failed
2. Create `frontend/src/components/POCheckResults.tsx`:
   - Display errors grouped by check type
   - Show line number, expected vs actual values

### Phase 6: Testing
1. Test with Chennai PO (4153514911.pdf or 4283143358.pdf)
2. Test with International PO (the multi-PO files)
3. Verify all 5 checks work correctly

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `backend/app/services/po_checker.py` | CREATE | PO validation logic |
| `backend/app/models/po_check_result.py` | CREATE | Result data model |
| `backend/app/routers/extraction.py` | MODIFY | Add /api/check-po endpoint |
| `frontend/src/api/poChecker.ts` | CREATE | API client for check |
| `frontend/src/pages/ExtractionPage.tsx` | MODIFY | Add check button + results |
| `frontend/src/components/POCheckResults.tsx` | CREATE | Error display component |

---

## PO Checker Lookup Files (Ready)

```
data/customers/emerson/lookups/po_checker/
├── Master list of Drawings & Specifications_ latest Revision.xlsx
│   └── Sheets: Latest Drawings (~994), Latest FMS (~20), SPECIFICATIONS (~16)
├── Master Price List $ _ JD Jones _ Effective 1st March 25.xlsx
│   └── ~988 parts, USD pricing
└── Master Price List INR _ JD Jones _ 1st March 25 (P&F Inclusive).xlsx
    └── ~988 parts, INR pricing
```

---

## Verification Plan

1. **Backend Unit Test:**
   - Run `python -m pytest backend/tests/test_po_checker.py`

2. **Manual Test - Chennai PO:**
   - Upload `4153514911.pdf` or `4283143358.pdf`
   - Click "Check PO"
   - Verify prices checked against INR list
   - Verify transit time uses 8-day rule

3. **Manual Test - International PO:**
   - Upload one of the multi-PO files
   - Click "Check PO"
   - Verify prices checked against USD list
   - Verify transit time uses 14-day rule

4. **End-to-End:**
   - Check PO → Fix any errors → Generate SO

---

## Status: READY TO IMPLEMENT

All validation rules defined:
- ✅ Chennai detection (address contains "Chennai" or "India")
- ✅ 5 validation checks specified
- ✅ Error handling (block until fixed)
- ✅ Data normalization requirements
- ✅ Sample POs available for testing
