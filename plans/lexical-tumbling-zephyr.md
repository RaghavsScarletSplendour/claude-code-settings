# Invite Code System for Restricted Signup

## Goal
Restrict signups so only users with a valid invite code can create accounts.

**Requirements:**
- Single-use codes (one person per code)
- 10 codes initially
- 30-day expiration

---

## Implementation Steps

### 1. Create Database Table
Run this SQL in Supabase:
```sql
CREATE TABLE invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(12) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
  used_at TIMESTAMPTZ DEFAULT NULL,
  used_by_clerk_id VARCHAR(255) DEFAULT NULL
);

CREATE INDEX idx_invite_codes_code ON invite_codes(code);
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "No direct user access" ON invite_codes FOR ALL USING (false);
```

### 2. Create Files

| File | Purpose |
|------|---------|
| `app/invite/page.tsx` | Invite code entry form |
| `app/sign-up/[[...sign-up]]/page.tsx` | Gated signup page (checks for valid invite) |
| `app/api/invite/validate/route.ts` | Validates code, sets cookie |
| `app/api/invite/consume/route.ts` | Marks code as used |
| `app/api/webhooks/clerk/route.ts` | Clerk webhook for user.created |
| `lib/invite-codes.ts` | Helper functions for code operations |
| `scripts/generate-codes.ts` | Script to generate invite codes |

### 3. Modify Middleware
Update `middleware.ts` to add public routes:
- `/sign-up(.*)`
- `/invite(.*)`
- `/api/invite/(.*)`
- `/api/webhooks/(.*)`

### 4. Generate Initial Codes
Run script to create 10 codes with 30-day expiry.

---

## User Flow

```
1. User visits /sign-up → Redirected to /invite (no valid code)
2. User enters invite code at /invite
3. API validates code (exists, not used, not expired)
4. If valid: Set cookie, redirect to /sign-up
5. /sign-up checks cookie, shows Clerk SignUp component
6. User completes Clerk signup
7. Clerk webhook fires → marks code as used
```

---

## Files to Modify

- `middleware.ts` - Add public routes for invite/signup flow

## Critical Files to Reference

- `lib/supabase.ts` - Has `getSupabaseServiceClient()` for admin operations
- `app/sign-in/[[...sign-in]]/page.tsx` - Pattern for Clerk page styling
- `components/ui/FormInput.tsx` - Reusable input component
- `components/ui/Button.tsx` - Reusable button component

---

## Clerk Webhook Setup Required

After implementation, configure in Clerk Dashboard:
1. Go to Webhooks
2. Add endpoint: `https://your-domain.com/api/webhooks/clerk`
3. Subscribe to `user.created` event
4. Copy webhook secret to `.env.local` as `CLERK_WEBHOOK_SECRET`
