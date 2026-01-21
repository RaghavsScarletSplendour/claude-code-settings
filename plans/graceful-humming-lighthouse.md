# NextPrompt UI Redesign Plan

## Summary
Redesign the Prompt Bank application to "NextPrompt" with Apple.com-like simplicity: horizontal header navigation, soft gradient backgrounds, and consistent styling across all pages.

## Design Decisions (Confirmed)
- **Brand**: "NextPrompt"
- **Navigation**: Horizontal header (replacing sidebar)
- **Pages**: Home, Gallery, Search (existing functionality preserved)
- **Background**: Simple soft blue/lavender gradient (no geometric shapes)

---

## Tasks

### 1. Update Global Styles
**File**: `/app/globals.css`
- [ ] Add soft gradient background CSS (light blue/lavender)
- [ ] Update color variables for the new design

### 2. Create Header Component
**File**: `/components/Header.tsx` (new)
- [ ] Create horizontal header with:
  - "NextPrompt" logo/text on left
  - Navigation links (Home, Gallery, Search) centered or right
  - UserMenu on far right
- [ ] Style with white/transparent background, subtle border
- [ ] Add active state styling for current page

### 3. Update Root Layout
**File**: `/app/layout.tsx`
- [ ] Remove Sidebar import and component
- [ ] Add new Header component
- [ ] Apply gradient background to main container
- [ ] Ensure proper spacing/padding for new layout

### 4. Redesign Home Page
**File**: `/app/page.tsx`
- [ ] Hero section with large "Welcome to NextPrompt" heading
- [ ] Subtitle: "Your personal vault for AI and technology prompts. Store, organize, and discover."
- [ ] Two CTA buttons: "Get Started" (filled dark) and "Learn More" (outline)
- [ ] Add subtle hover animations on buttons
- [ ] Center content vertically and horizontally

### 5. Update Gallery Page Styling
**File**: `/app/gallery/page.tsx`
- [ ] Update "Your Prompts" heading typography
- [ ] Ensure consistent spacing with new layout
- [ ] Style category filter and Add button to match design

### 6. Update Search Page Styling
**File**: `/app/search/page.tsx`
- [ ] Update "Search Prompts" heading typography
- [ ] Style search input to match design
- [ ] Style mode toggle buttons consistently

### 7. Update PromptCard Component
**File**: `/components/PromptCard.tsx`
- [ ] Update card styling: white bg, subtle shadow, rounded corners
- [ ] Ensure tags/categories display as pills (already have CategoryBadge)
- [ ] Smooth hover transition on cards

### 8. Delete Sidebar Component
**File**: `/components/Sidebar.tsx`
- [ ] Remove this file (no longer needed)

### 9. Update Metadata
**File**: `/app/layout.tsx`
- [ ] Change title from "Prompt Bank" to "NextPrompt"
- [ ] Update description if needed

---

## Files to Modify
1. `/app/globals.css` - Global styles + gradient
2. `/components/Header.tsx` - New file
3. `/app/layout.tsx` - Layout restructure
4. `/app/page.tsx` - Home page hero
5. `/app/gallery/page.tsx` - Styling updates
6. `/app/search/page.tsx` - Styling updates
7. `/components/PromptCard.tsx` - Card styling
8. `/components/Sidebar.tsx` - Delete

## Design Specs (from mockups)
- **Background gradient**: Soft blue/lavender (#f8fafc to #e0e7ff)
- **Primary font**: Geist Sans (already configured)
- **Heading sizes**: Home hero ~4xl-5xl, Page titles ~2xl
- **Button styles**:
  - Primary: Dark bg (#1f2937), white text, rounded-full
  - Secondary: White/transparent bg, border, rounded-full
- **Card styles**: White bg, border-gray-200, rounded-lg, shadow-sm

---

## Review Section
(To be filled after implementation)
