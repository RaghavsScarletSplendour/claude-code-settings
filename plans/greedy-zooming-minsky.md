# Razorpay Subscription Integration Plan

## Overview
Replace Stripe with Razorpay for subscription payments in the Focus First Learning App. Razorpay supports both Indian (UPI, cards, net banking) and international (Apple Pay, Visa, Mastercard) payments.

## Prerequisites (User Actions Required)
1. Create Razorpay account at https://dashboard.razorpay.com
2. Generate Test Mode API keys: Dashboard → Account & Settings → API Keys
3. Create a subscription Plan in Dashboard: Subscriptions → Plans → Create Plan
   - Name: "Focus Pro"
   - Billing cycle: Monthly
   - Amount: Set your price (e.g., ₹299/month or $5/month)
   - Note the `plan_id` (starts with `plan_`)

## Architecture

### Pricing Tiers
```
Free Tier:
- 3 summarizations/day
- 3 items/day
- No Architect feature
- No cross-device sync (wait - sync is already free via Supabase auth)

Pro Tier:
- Unlimited summarizations
- Unlimited items
- Architect feature enabled
- Priority support
```

### Files to Create

```
lib/
├── razorpay/
│   ├── server.ts          # Razorpay server instance + tier limits
│   └── client.ts          # Client-side Razorpay loader
├── subscription.ts        # Subscription helpers (getUserSubscription, checkUsage, etc.)

app/api/
├── razorpay/
│   ├── create-subscription/route.ts  # Create subscription for user
│   └── webhook/route.ts              # Handle Razorpay webhooks
├── subscription/
│   └── status/route.ts               # Get user's subscription status

components/
├── PaywallModal.tsx       # Upgrade prompt when limit reached
└── UsageBadge.tsx         # Shows usage in header

hooks/
└── useSubscription.ts     # Client-side subscription state

supabase/migrations/
└── 001_subscriptions.sql  # Database tables
```

### Files to Modify
- `app/api/summarize/route.ts` - Add usage limit checks
- `app/api/architect/route.ts` - Add pro feature check
- `app/page.tsx` - Add UsageBadge and PaywallModal
- `package.json` - Add razorpay dependency
- `.env.example` - Add Razorpay env vars

---

## Implementation Steps

### Step 1: Environment Variables
Add to `.env.example` and `.env.local`:
```env
RAZORPAY_KEY_ID=rzp_test_xxxxx
RAZORPAY_KEY_SECRET=xxxxx
RAZORPAY_WEBHOOK_SECRET=xxxxx
RAZORPAY_PLAN_ID=plan_xxxxx
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_xxxxx
```

### Step 2: Install Dependencies
```bash
npm install razorpay
```

### Step 3: Database Schema (Supabase)
Create `supabase/migrations/001_subscriptions.sql`:

```sql
-- User subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users ON DELETE CASCADE,
  razorpay_customer_id TEXT,
  razorpay_subscription_id TEXT,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'authenticated', 'pending', 'halted', 'cancelled', 'completed', 'expired')),
  current_period_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily usage tracking
CREATE TABLE IF NOT EXISTS daily_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  summarizations INT DEFAULT 0,
  items_created INT DEFAULT 0,
  UNIQUE(user_id, date)
);

-- Indexes
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_daily_usage_user_date ON daily_usage(user_id, date);

-- RLS policies
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own usage" ON daily_usage
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own usage" ON daily_usage
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Auto-create subscription on signup
CREATE OR REPLACE FUNCTION handle_new_user_subscription()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_subscriptions (user_id, tier, status)
  VALUES (NEW.id, 'free', 'active')
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_subscription ON auth.users;
CREATE TRIGGER on_auth_user_created_subscription
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_subscription();

-- Increment usage function
CREATE OR REPLACE FUNCTION increment_usage(p_user_id UUID, p_date DATE, p_column TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO daily_usage (user_id, date, summarizations, items_created)
  VALUES (p_user_id, p_date, 0, 0)
  ON CONFLICT (user_id, date) DO NOTHING;

  IF p_column = 'summarizations' THEN
    UPDATE daily_usage SET summarizations = summarizations + 1 WHERE user_id = p_user_id AND date = p_date;
  ELSIF p_column = 'items_created' THEN
    UPDATE daily_usage SET items_created = items_created + 1 WHERE user_id = p_user_id AND date = p_date;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Step 4: Server-side Razorpay Setup
Create `lib/razorpay/server.ts`:
- Initialize Razorpay instance with API keys
- Define TIER_LIMITS constant (free: 3/day, pro: unlimited)
- Export getRazorpayServer() function

### Step 5: Client-side Razorpay Loader
Create `lib/razorpay/client.ts`:
- Load Razorpay checkout script dynamically
- Export loadRazorpay() function

### Step 6: Subscription Helpers
Create `lib/subscription.ts`:
- `getUserSubscription(userId)` - Get user's subscription from DB
- `checkUsageLimit(userId, action)` - Check if user can perform action
- `incrementUsage(userId, action)` - Increment usage counter
- `getCurrentUsage(userId)` - Get usage for display

### Step 7: API Routes

**`/api/razorpay/create-subscription/route.ts`**:
1. Get authenticated user
2. Create Razorpay customer (if not exists)
3. Create subscription with plan_id
4. Return subscription_id for checkout

**`/api/razorpay/webhook/route.ts`**:
1. Verify webhook signature
2. Handle events:
   - `subscription.authenticated` - Mark subscription as authenticated
   - `subscription.activated` - Upgrade user to pro tier
   - `subscription.charged` - Extend current_period_end
   - `subscription.cancelled` - Downgrade to free tier
   - `subscription.halted`/`subscription.pending` - Handle payment failures

**`/api/subscription/status/route.ts`**:
1. Get authenticated user
2. Return subscription tier, status, usage

### Step 8: Update Existing API Routes

**`/api/summarize/route.ts`**:
- Add usage check before processing
- Increment usage after success
- Return 403 with upgrade prompt if limit exceeded

**`/api/architect/route.ts`**:
- Add pro feature check
- Return 403 if not pro tier

### Step 9: React Components

**`components/PaywallModal.tsx`**:
- Modal showing upgrade benefits
- "Upgrade to Pro" button that triggers Razorpay checkout
- Shows current usage vs limits

**`components/UsageBadge.tsx`**:
- Shows "3/3 used today" or "Pro" badge
- Click opens upgrade modal (for free users)

### Step 10: Subscription Hook
Create `hooks/useSubscription.ts`:
- Fetch subscription status on mount
- Provide `tier`, `usage`, `canSummarize`, `canUseArchitect`
- `triggerUpgrade()` function to open Razorpay checkout

### Step 11: Update Main Page
Modify `app/page.tsx`:
- Add UsageBadge to header
- Wrap summarize action with usage check
- Show PaywallModal when limit reached

---

## Razorpay Checkout Flow

```
1. User clicks "Upgrade to Pro"
2. Frontend calls POST /api/razorpay/create-subscription
3. Backend creates Razorpay subscription, returns subscription_id
4. Frontend opens Razorpay Checkout with subscription_id
5. User completes payment (UPI/Card/Apple Pay)
6. Razorpay sends webhook to /api/razorpay/webhook
7. Backend updates user_subscriptions table
8. Frontend refreshes subscription status
```

---

## Webhook Events to Handle

| Event | Action |
|-------|--------|
| `subscription.authenticated` | Store subscription_id, status='authenticated' |
| `subscription.activated` | Set tier='pro', status='active' |
| `subscription.charged` | Update current_period_end |
| `subscription.cancelled` | Set tier='free', status='cancelled' |
| `subscription.halted` | Set status='halted', show warning |
| `subscription.pending` | Set status='pending' |

---

## Testing Plan

1. **Unit test subscription helpers** - Mock Supabase, test usage limits
2. **Test webhook handling** - Use Razorpay test mode webhooks
3. **E2E test checkout flow**:
   - Create test user
   - Verify free tier limits work
   - Complete test payment (Razorpay provides test cards)
   - Verify pro tier unlocked
   - Test cancellation flow

### Test Cards (Razorpay Test Mode)
- Success: 4111 1111 1111 1111
- UPI: success@razorpay

---

## Verification Checklist

- [ ] Razorpay API keys configured in .env.local
- [ ] Database migration applied in Supabase
- [ ] Free users limited to 3 summarizations/day
- [ ] Pro users have unlimited access
- [ ] Architect feature gated to pro tier
- [ ] Webhook endpoint receives and processes events
- [ ] Checkout flow completes successfully in test mode
- [ ] Usage badge shows correct counts
- [ ] Paywall modal appears when limit reached

---

## Files Summary

| File | Purpose |
|------|---------|
| `lib/razorpay/server.ts` | Server Razorpay instance |
| `lib/razorpay/client.ts` | Client checkout loader |
| `lib/subscription.ts` | Subscription/usage helpers |
| `app/api/razorpay/create-subscription/route.ts` | Create subscription |
| `app/api/razorpay/webhook/route.ts` | Handle webhooks |
| `app/api/subscription/status/route.ts` | Get status |
| `components/PaywallModal.tsx` | Upgrade modal |
| `components/UsageBadge.tsx` | Usage display |
| `hooks/useSubscription.ts` | Client subscription state |
| `supabase/migrations/001_subscriptions.sql` | DB schema |

---

## Notes

- Apple Pay works for US customers via Razorpay International
- UPI works for Indian customers
- Same webhook handles all payment methods
- Test thoroughly in test mode before going live
- Switch to live keys only after full testing
