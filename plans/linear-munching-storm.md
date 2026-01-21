# Code Principles Review - New Issues Found

**Review Date:** January 6, 2026

---

## Principle Violations

### 14. DRY Violation: Service/Controller Boilerplate

**Files:**
- `backend/services/productEstimationService.js` - estimate703, estimate710VAngular, estimateB3_707, estimateB3_707LE (4 identical patterns)
- `backend/controllers/productsController.js` - calculate703Estimation, calculateProduct710VAngular, calculateProductB3_707, calculateProductB3_707_LE (4 identical patterns)

**Issue:** 8 nearly identical functions across two files. Each service function fetches config and calls engine. Each controller function calls service and returns JSON. Pattern is so repetitive it could be generated from config.

**Principle:** DRY (Don't Repeat Yourself)

**Impact:** Adding a new product requires copy-pasting boilerplate to both files. High maintenance burden. Easy to introduce inconsistencies when modifying one function but forgetting others.

---

### 15. Readability: Inconsistent Field Naming (`id_` vs `id`)

**Files:**
- `frontend/src/validators/product703Validator.js` - uses `inputs.id_`
- `frontend/src/validators/productB3_707Validator.js` - uses `inputs.id_`
- `frontend/src/validators/productB3_707LEValidator.js` - uses `inputs.id_`
- `frontend/src/validators/product710AngularValidator.js` - uses `inputs.id`
- `frontend/src/utils/productUtils/intialStates.js` - mixed usage
- `backend/calculationEngine/core/StandardRingCalculator.js` - uses `id_`

**Issue:** The field name for "Inner Diameter" is inconsistent. Standard ring products use `id_` (with underscore) while Angular product uses `id` (without underscore). Variable names read from different field names creating confusion.

**Principle:** Meaningful Naming / Principle of Least Astonishment (POLA)

**Impact:** Developers must remember which convention applies to which product. Copy-pasting code between products introduces subtle bugs. Confusing that variable `id` reads from field `id_` in some files.

---

### 16. YAGNI: Unnecessary Promise.resolve Wrappers

**Files:**
- `frontend/src/utils/productCalculatorConfigs.js` - apiFunction, validator, transformer for all 4 products

**Issue:** Synchronous imports wrapped in `Promise.resolve()` without actual async behavior. Comment says "maintain async interface" but all functions are already loaded synchronously via static imports.

**Principle:** YAGNI (You Ain't Gonna Need It)

**Impact:** Suggests dynamic imports that don't exist. Adds unnecessary async complexity to consuming code (`Promise.all` in GenericProductCalculator). Misleading code that implies lazy loading.

---

### 17. SRP Concern: StandardRingCalculator Multi-Responsibility

**Files:**
- `backend/calculationEngine/core/StandardRingCalculator.js` - calculateStandardRing function (170 lines)

**Issue:** Single function handles 8 distinct responsibilities: metadata extraction, input parsing, validation, geometry calculations, weight calculations, material cost calculations, labour cost calculations, and building display/export data.

**Principle:** Single Responsibility Principle (SRP)

**Impact:** Function is 170 lines long. Testing individual calculations requires mocking entire flow. Changes to display format affect calculation file. Hard to reuse individual calculations elsewhere.
