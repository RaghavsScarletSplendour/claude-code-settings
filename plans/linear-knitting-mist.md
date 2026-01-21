# Plan: Add X Account and Update Beta Code Request Flow

## Summary
Add X (Twitter) account link to the landing page and change the beta code request to redirect to Twitter DM instead of email.

## Changes Required

### 1. Update Beta Access Page (`app/beta-access/page.tsx`)
**Line 135-143** - Change the footer text from:
```
Don't have a code? Request access (mailto:support@promptr.app)
```
To:
```
Don't have a code? DM me on X (https://x.com/raghavbajoria11)
```

### 2. Add X Link to CTASection (`components/landing/CTASection.tsx`)
Add X/Twitter link below the "Sign Up Free" button:
- Text: "Follow me on X" or X icon with @raghavbajoria11
- URL: `https://x.com/raghavbajoria11`
- Style: Subtle gray text link matching the design

## Files to Modify
1. `/app/beta-access/page.tsx` - Change email to X link (line 135-143)
2. `/components/landing/CTASection.tsx` - Add X link below CTA button (after line 26)
