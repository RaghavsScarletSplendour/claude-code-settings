# Plan: Separate Single Page into Home, Gallery, and Search Pages

## Current State
- All functionality is in `/app/page.tsx`: prompts display, add button, and search
- Components already exist: PromptGallery, PromptCard, PromptForm, etc.

## Goal
Split into 3 pages without adding new features:
1. **Home** (`/`) - Welcome text only
2. **Gallery** (`/gallery`) - All prompts + Add Prompt button
3. **Search** (`/search`) - Search functionality (empty until user types)

## Implementation Steps

### Step 1: Create Sidebar Component
- Create `components/Sidebar.tsx`
- Left sidebar with navigation links: Home, Gallery, Search
- Style consistently with existing app design

### Step 2: Update Layout
- Modify `app/layout.tsx` to include the Sidebar
- Set up flex layout: sidebar on left, main content on right

### Step 3: Create Gallery Page
- Create `app/gallery/page.tsx`
- Move prompts fetching, display (PromptGallery), and Add Prompt button from current `page.tsx`
- Keep the PromptForm modal for adding prompts
- Remove the search input (that goes to Search page)

### Step 4: Create Search Page
- Create `app/search/page.tsx`
- Move search input from current page
- Show empty state initially ("Search for prompts...")
- Display filtered results only after user types
- Reuse PromptGallery to display search results

### Step 5: Update Home Page
- Simplify `app/page.tsx` to show welcome text only
- Simple welcome message like "Welcome to Prompt Bank"
- Remove all prompt-related functionality (moved to Gallery)

## Files to Create
- `components/Sidebar.tsx` - New sidebar component
- `app/gallery/page.tsx` - Gallery page
- `app/search/page.tsx` - Search page

## Files to Modify
- `app/layout.tsx` - Add sidebar to layout
- `app/page.tsx` - Simplify to welcome text only

## Files to Keep Unchanged
- `components/PromptGallery.tsx`
- `components/PromptCard.tsx`
- `components/PromptForm.tsx`
- `components/PromptDetailModal.tsx`
- `components/UserMenu.tsx`
- `components/Modal.tsx`
- `components/ConfirmDialog.tsx`
- API routes and utilities
