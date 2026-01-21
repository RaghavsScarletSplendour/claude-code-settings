# Plan: Edit Prompt Feature

## Overview
Add ability to edit existing prompts by reusing existing components (DRY principle).

## Changes Required

### 1. Add PUT endpoint to API
**File**: `app/api/prompts/route.ts`

- Add `PUT` handler similar to existing POST
- Accepts `id`, `name`, `tags`, `content` in body
- Uses existing `validatePromptInput` function
- Updates prompt in Supabase where `id` and `user_id` match

### 2. Extend PromptForm for edit mode
**File**: `components/PromptForm.tsx`

- Add optional `prompt` prop for edit mode
- Add `mode` prop: `"create"` | `"edit"` (default: create)
- Pre-populate fields when `prompt` is provided
- Change submit to PUT when editing (include `id`)
- Update title: "Add New Prompt" vs "Edit Prompt"

### 3. Add Edit button to PromptCard menu
**File**: `components/PromptCard.tsx`

- Add `onEdit` callback prop
- Add Edit button in dropdown menu (above Delete)
- Call `onEdit(prompt)` when clicked

### 4. Wire up edit flow in PromptGallery
**File**: `components/PromptGallery.tsx`

- Add `onEdit` prop to pass through to PromptCard
- Pass the handler to each card

### 5. Add edit state management in page.tsx
**File**: `app/page.tsx`

- Add `editPrompt` state (null or Prompt object)
- Pass edit handler to PromptGallery
- Pass `editPrompt` to PromptForm when editing
- Clear edit state on form close/success

## Todo Checklist
- [ ] Add PUT endpoint to `app/api/prompts/route.ts`
- [ ] Extend `components/PromptForm.tsx` for edit mode
- [ ] Add Edit button to `components/PromptCard.tsx`
- [ ] Wire up `components/PromptGallery.tsx`
- [ ] Add edit state in `app/page.tsx`

## Files to Modify
1. `app/api/prompts/route.ts` - Add PUT endpoint
2. `components/PromptForm.tsx` - Support create/edit modes
3. `components/PromptCard.tsx` - Add Edit button
4. `components/PromptGallery.tsx` - Pass onEdit handler
5. `app/page.tsx` - Manage edit state
