# Plan: Fix DRY Violations

## Overview
Extract duplicate code into reusable components and hooks to follow DRY principles.

## Files to Create

### 1. Shared Hook
- **`hooks/useClickOutside.ts`** - Custom hook for click-outside detection

### 2. Shared Components
- **`components/ui/CopyButton.tsx`** - Reusable copy-to-clipboard button with icon states
- **`components/ui/CategorySelect.tsx`** - Reusable category dropdown

## Files to Modify

### 1. Type Usage
- **`components/PromptCard.tsx`** - Import `Prompt` from `lib/types.ts` instead of local interface
- **`components/PromptDetailModal.tsx`** - Import `Prompt` from `lib/types.ts` instead of local interface

### 2. Use New Components/Hooks
- **`components/PromptCard.tsx`** - Use `useClickOutside`, `CopyButton`
- **`components/PromptDetailModal.tsx`** - Use `useClickOutside`, `CopyButton`, `CategorySelect`
- **`components/PromptForm.tsx`** - Use `CategorySelect`

---

## Step-by-Step Tasks

- [ ] 1. Update `lib/types.ts` - Add `similarity` field to make Prompt interface complete
- [ ] 2. Update `components/PromptCard.tsx` - Import `Prompt` from `lib/types.ts`, remove local interface
- [ ] 3. Update `components/PromptDetailModal.tsx` - Import `Prompt` from `lib/types.ts`, remove local interface
- [ ] 4. Create `hooks/useClickOutside.ts` - Extract click-outside logic
- [ ] 5. Create `components/ui/CopyButton.tsx` - Extract copy button with icons
- [ ] 6. Create `components/ui/CategorySelect.tsx` - Extract category dropdown
- [ ] 7. Refactor `PromptCard.tsx` - Use new hook and component
- [ ] 8. Refactor `PromptDetailModal.tsx` - Use new hook and components
- [ ] 9. Refactor `PromptForm.tsx` - Use CategorySelect component
- [ ] 10. Test the application

---

## Notes
- Keep changes minimal and focused
- Maintain existing functionality
- No visual changes to UI
