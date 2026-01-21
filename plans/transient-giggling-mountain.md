# Plan: Fix Input Validation in Prompts API

## Problem
- Validation logic is duplicated between API route and client form
- Constants (100, 10000, 500) are hardcoded in both files
- Minimal sanitization (only `.trim()`) - no control character stripping
- Violates DRY principle

## Solution
Create a shared validation module used by both client and server.

---

## Tasks

- [ ] Create `/lib/validations.ts` with shared validation logic
- [ ] Update `/app/api/prompts/route.ts` to use shared validation
- [ ] Update `/components/PromptForm.tsx` to use shared validation and constants

---

## Implementation Details

### 1. Create `/lib/validations.ts`

New file containing:
- **Constants**: `PROMPT_LIMITS` object with maxLength for each field
- **Sanitization helper**: Strip control characters (except newlines in content)
- **Validation function**: `validatePromptInput()` returns either sanitized data or error

```typescript
export const PROMPT_LIMITS = {
  name: { maxLength: 100 },
  content: { maxLength: 10000 },
  tags: { maxLength: 500 },
} as const;

export function validatePromptInput(input: unknown): ValidationResult
```

### 2. Update `/app/api/prompts/route.ts`

- Import `validatePromptInput` from `@/lib/validations`
- Replace inline validation (lines 35-60) with single function call
- Use returned sanitized data for database insert

### 3. Update `/components/PromptForm.tsx`

- Import `PROMPT_LIMITS` and `validatePromptInput`
- Replace hardcoded `maxLength` attributes with constants
- Replace inline validation (lines 24-48) with shared function

---

## Files to Modify

| File | Action |
|------|--------|
| `lib/validations.ts` | Create new (~50 lines) |
| `app/api/prompts/route.ts` | Simplify validation |
| `components/PromptForm.tsx` | Use shared validation + constants |

---

## Security Improvements

1. **Control character stripping** - Prevents invisible character injection
2. **Type checking** - Validates input is object before destructuring
3. **Consistent sanitization** - Same logic on client and server
4. **No new dependencies** - Keeps bundle size small

## What This Does NOT Change

- No new libraries (keeps it simple)
- No database schema changes
- No authentication changes

---

## Review

### Summary of Changes

1. **Created `/lib/validations.ts`** (~60 lines)
   - `PROMPT_LIMITS` constants object for max lengths
   - `validatePromptInput()` function that validates and sanitizes input
   - `sanitizeString()` helper that strips control characters

2. **Simplified `/app/api/prompts/route.ts`**
   - Replaced ~25 lines of inline validation with ~8 lines using shared function
   - Added import for `validatePromptInput`

3. **Updated `/components/PromptForm.tsx`**
   - Replaced ~20 lines of inline validation with shared function call
   - Changed hardcoded `maxLength` values to use `PROMPT_LIMITS` constants
   - Added import for `PROMPT_LIMITS` and `validatePromptInput`

### Security Improvements
- Control character stripping prevents invisible character injection
- Proper type checking validates input is object before destructuring
- Consistent sanitization on client and server

### DRY Principle
- Validation logic now in single location (`lib/validations.ts`)
- Constants usable in both validation and HTML attributes
