# Plan: Update Landing Page Reveal Card Content

## Summary
Replace the placeholder "Grok 4.20" content in the reveal card with warm, inviting copy centered on "Find Your Focus".

## File to Modify
- `components/landing/RevealCard.tsx`

## Final Card Content

**Badge:** `Focus First | One Thing at a Time`

**Headline:** Find Your Focus

**Description:** Welcome to clarity. One insight at a time, no distractions. Focus First helps you learn what matters in AI/ML - without the noise.

**Button:** `Get Started`

## Implementation
Update RevealCard.tsx:
1. Replace badge text from "Web Development | Level 6/10"
2. Replace headline from "Grok 4.20 - Granite"
3. Replace description paragraph
4. Replace button text from "Mark as Learned"

## Verification
- Run `npm run dev` and visit localhost:3000
- Move cursor over the lens to reveal the card
- Check mobile view (static card fallback)
