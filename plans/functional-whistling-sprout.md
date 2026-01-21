# Plan: Fix Code Principle Violations

## Summary
Fix 12 code principle violations identified in the codebase review, organized into 4 implementation batches prioritized by impact and related changes.

---

## Batch 1: Backend DRY Fixes (High Priority)

### 1A. Create Shared Excel Loading Utility
**Violations:** #1 (Excel Loading), #3 (Normalizers), #4 (Inline Imports), #8 (Magic Numbers)

**New Files:**
- `/backend/app/utils/excel_loader.py` - Common `load_excel_data()` function
- `/backend/app/utils/normalizers.py` - Shared `normalize_text()`, `normalize_fms_code()`, `extract_rev_letter()`

**Modify:**
- `/backend/app/services/lookup_service.py` - Use shared utilities, remove duplicate methods
- `/backend/app/services/po_checker.py` - Use shared utilities, remove duplicate methods
- `/backend/app/services/pdf_extractor.py` - Move inline `import re` to top of file
- `/backend/app/services/po_checker.py` - Add docstrings explaining transit time constants

**Testing:** Run `pytest backend/tests/` - all existing tests should pass

---

## Batch 2: Total Calculation & Mutation Fixes (High Priority)

### 2A. Create Shared Calculation Utilities
**Violations:** #2 (Total Calculation DRY), #9 (Input Mutation)

**New Files:**
- `/backend/app/utils/calculations.py` - `calculate_order_total()`, `calculate_line_item_total()`
- `/frontend/src/utils/calculations.ts` - TypeScript equivalents

**Modify:**
- `/backend/app/models/po_data.py` - Use shared calculation in `model_post_init`
- `/backend/app/services/data_cleaner.py` - Use shared calculation; return NEW object instead of mutating input
- `/frontend/src/pages/ExtractionPage.tsx` - Import `calculateOrderTotal()`
- `/frontend/src/components/extraction/LineItemsTable.tsx` - Import `calculateOrderTotal()`
- `/frontend/src/hooks/usePurchaseOrder.ts` - Import `calculateOrderTotal()`

**Testing:**
- Add unit tests for calculation utilities
- Add test verifying DataCleaner doesn't mutate input
- Manual: Upload PDF, verify totals display correctly

---

## Batch 3: Config Externalization (Medium Priority)

### 3A. Move Hardcoded Paths to Config
**Violations:** #7 (Hardcoded Paths), #12 (Token Key Duplication)

**New Files:**
- `/frontend/src/constants/auth.ts` - Export `TOKEN_KEY = 'auth_token'`

**Modify:**
- `/backend/app/config.py` - Add to `customer_lookup_files`:
  ```python
  "price_list_usd": "Master Price List $ _ JD Jones _ Effective 1st March 25.xlsx",
  "price_list_inr": "Master Price List INR _ JD Jones _ 1st March 25 (P&F Inclusive).xlsx",
  "drawings_specs": "Master list of Drawings & Specifications_ latest Revision.xlsx",
  ```
- `/backend/app/services/po_checker.py` - Use `settings.get_lookup_filename()` instead of hardcoded strings
- `/frontend/src/contexts/AuthContext.tsx` - Import TOKEN_KEY from constants
- `/frontend/src/api/client.ts` - Import TOKEN_KEY from constants

**Testing:**
- Test PO validation with correct/missing files
- Manual: Test login/logout flow in browser

---

## Batch 4: Cleanup (Low Priority)

### 4A. Remove Unused Code & Add Logging
**Violations:** #5 (Fail Fast), #10 (Unused Code)

**Modify:**
- `/backend/app/services/so_generator.py` - Delete `generate_console_output()` method (80 lines)
- `/backend/app/services/lookup_service.py` - Add `logger.debug()` when lookup returns None

**Testing:**
- Verify no code references `generate_console_output`
- Run existing tests

---

## Deferred (Optional Future Work)

### 5A. PDFExtractor SRP Refactoring
**Violation:** #6 (SRP)

Defer splitting 540-line `PDFExtractor` class. Risk is too high for current iteration. Consider when:
- Adding support for new PDF formats
- Major bugs require header/line-item logic changes

### 5B. Frontend Interface Slimming
**Violation:** #11 (Fat Interfaces)

Minor issue - TypeScript's structural typing handles this gracefully. Use `Pick<POLineItem, ...>` where appropriate.

---

## Files Summary

| File | Changes |
|------|---------|
| **New Backend Utils** | |
| `backend/app/utils/excel_loader.py` | Create: shared Excel loading |
| `backend/app/utils/normalizers.py` | Create: text normalization |
| `backend/app/utils/calculations.py` | Create: total calculation |
| **New Frontend Utils** | |
| `frontend/src/utils/calculations.ts` | Create: total calculation |
| `frontend/src/constants/auth.ts` | Create: TOKEN_KEY constant |
| **Backend Service Modifications** | |
| `backend/app/services/lookup_service.py` | Use utils, add logging |
| `backend/app/services/po_checker.py` | Use utils, use config paths |
| `backend/app/services/data_cleaner.py` | Use calculations, fix mutation |
| `backend/app/services/so_generator.py` | Remove unused method |
| `backend/app/services/pdf_extractor.py` | Move inline imports |
| `backend/app/models/po_data.py` | Use calculations util |
| `backend/app/config.py` | Add lookup file mappings |
| **Frontend Modifications** | |
| `frontend/src/pages/ExtractionPage.tsx` | Use calculations util |
| `frontend/src/components/extraction/LineItemsTable.tsx` | Use calculations util |
| `frontend/src/hooks/usePurchaseOrder.ts` | Use calculations util |
| `frontend/src/contexts/AuthContext.tsx` | Import TOKEN_KEY |
| `frontend/src/api/client.ts` | Import TOKEN_KEY |

---

## Verification Steps

After each batch:

1. **Run Backend Tests:**
   ```bash
   cd backend && pytest tests/ -v
   ```

2. **Run Frontend Type Check:**
   ```bash
   cd frontend && npm run build
   ```

3. **Manual End-to-End Test:**
   - Start backend: `cd backend && uvicorn app.main:app --reload`
   - Start frontend: `cd frontend && npm run dev`
   - Upload a sample PDF
   - Verify extraction works, totals are correct
   - Run PO validation
   - Generate Sales Order Excel
   - Test login/logout flow

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Excel loading breaks | Keep original methods, deprecate first |
| Total calculation differs | Unit tests comparing old vs new logic |
| Auth flow breaks | Test in browser before/after |
| Lookup failures hidden | Debug logging preserves observability |
