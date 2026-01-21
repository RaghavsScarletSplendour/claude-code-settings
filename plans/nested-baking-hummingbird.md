# Plan: Remove divider line between summary and link

## Change
Remove the horizontal divider line that appears between the summary text and the source URL link in the FocusCard component.

## File to modify
- `components/FocusCard.tsx:54`

## Implementation
Change line 54 from:
```tsx
<div className="mb-8 pt-4 border-t border-ink">
```
to:
```tsx
<div className="mb-8">
```

This removes the `pt-4 border-t border-ink` classes which create the top border and padding.

## Verification
- Run `npm run dev` and view a card with a source URL to confirm the divider is removed
