# Plan: Add "Move to Category" to 3-Dot Menu

## Summary
Add ability to quickly change a prompt's category from the 3-dot menu on prompt cards, without opening the edit modal.

---

## Implementation

### Single File Change: `components/PromptCard.tsx`

**Current 3-dot menu:**
- Edit
- Delete

**New 3-dot menu:**
- Edit
- Move to Category → (submenu with categories)
- Delete

---

## Steps

- [ ] **1.** Add `onCategoryChange` prop to PromptCard (callback after category update)
- [ ] **2.** Add state for showing category submenu
- [ ] **3.** Add "Move to Category" menu item that reveals submenu
- [ ] **4.** Submenu shows: "No Category" + all user categories
- [ ] **5.** On selection, call PUT `/api/prompts` with just the category_id change
- [ ] **6.** Call `onCategoryChange` to refresh the gallery

---

## Files to Modify

| File | Change |
|------|--------|
| `components/PromptCard.tsx` | Add category submenu to 3-dot menu |
| `app/gallery/page.tsx` | Pass `onCategoryChange={fetchPrompts}` to PromptGallery |
| `components/PromptGallery.tsx` | Pass `onCategoryChange` to PromptCard |

---

## UI Design

```
┌──────────────────┐
│ Edit             │
├──────────────────┤
│ Move to Category ▶ ┌─────────────────┐
├──────────────────┤ │ No Category     │
│ Delete           │ │ ─────────────── │
└──────────────────┘ │ Work            │
                     │ Personal        │
                     │ Ideas           │
                     └─────────────────┘
```
