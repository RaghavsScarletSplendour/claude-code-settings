# Delete Prompts Feature Plan

## Summary
Add ability to delete prompts with a three-dot menu on each card and a confirmation dialog.

## Supabase Changes
**None required.** The API uses the service role key which bypasses RLS. Authentication is handled via Clerk on the server side.

---

## Backend Changes

### File: `app/api/prompts/route.ts`

Add a `DELETE` handler:
1. Authenticate user via Clerk's `auth()`
2. Get prompt ID from request body
3. Verify the prompt belongs to the user (query with `user_id` filter)
4. Delete the prompt from Supabase
5. Return success/error response

---

## Frontend Changes

### 1. File: `components/PromptCard.tsx`

- Add three-dot menu button (top-right corner)
- Add dropdown menu with "Delete" option
- Accept `onDelete` callback prop from parent

### 2. New File: `components/ConfirmDialog.tsx`

- Reusable confirmation modal (follows existing PromptForm modal pattern)
- Props: `isOpen`, `onConfirm`, `onCancel`, `title`, `message`

### 3. File: `components/PromptGallery.tsx`

- Pass `onDelete` handler to each PromptCard
- Manage confirmation dialog state
- Call DELETE API and refresh prompts on confirm

### 4. File: `app/page.tsx`

- Pass `fetchPrompts` to PromptGallery (already done for PromptForm pattern)

---

## Files to Modify
1. `app/api/prompts/route.ts` - add DELETE handler
2. `components/PromptCard.tsx` - add three-dot menu
3. `components/PromptGallery.tsx` - handle delete flow
4. `components/ConfirmDialog.tsx` - new file for confirmation modal
