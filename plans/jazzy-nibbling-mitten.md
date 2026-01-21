# Stripe Subscription Paywall Implementation Plan

## Overview
Add a tiered subscription system using Stripe to monetize Focus First.

## Pricing Tiers

| | Free | Pro ($8/mo) |
|---|---|---|
| Items/day | 3 | Unlimited |
| AI Summarization | 3/day | Unlimited |
| Curriculum Architect | No | Yes |
| Cross-device Sync | No | Yes |
| Archive History | Last 10 | Unlimited |

## Implementation Phases

### Phase 1: Database Setup (Supabase)

Create new tables in Supabase:

```sql
-- User subscriptions
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users ON DELETE CASCADE,
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT,
  tier TEXT NOT NULL DEFAULT 'free',
  status TEXT NOT NULL DEFAULT 'active',
  current_period_end TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Daily usage tracking
CREATE TABLE daily_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  summarizations INT DEFAULT 0,
  items_created INT DEFAULT 0,
  UNIQUE(user_id, date)
);

-- RLS policies
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_usage ENABLE ROW LEVEL SECURITY;
```

### Phase 2: Stripe Setup

**Install dependencies:**
```bash
npm install stripe @stripe/stripe-js
```

**Environment variables (.env.local):**
```
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRO_PRICE_ID=price_...
```

**New files:**
```
lib/
  stripe/
    client.ts          # Browser Stripe instance
    server.ts          # Server Stripe instance

app/
  api/
    stripe/
      checkout/route.ts       # Create checkout session
      portal/route.ts         # Customer portal
      webhook/route.ts        # Handle Stripe events
```

### Phase 3: Subscription Check Middleware

**Create `/lib/subscription.ts`:**
```typescript
export async function getUserSubscription(userId: string) {
  // Fetch from user_subscriptions table
  // Return { tier, isActive, limits }
}

export async function checkUsageLimit(userId: string, action: 'summarize' | 'architect') {
  // Check daily_usage against tier limits
  // Return { allowed, remaining, limit }
}

export async function incrementUsage(userId: string, action: 'summarize' | 'architect') {
  // Increment daily_usage counter
}
```

### Phase 4: Gate API Endpoints

**Modify `/api/summarize/route.ts`:**
1. Get user from session
2. Check subscription tier
3. Check daily usage limit
4. If over limit → return 402 with upgrade prompt
5. Process request
6. Increment usage counter

**Modify `/api/architect/route.ts`:**
1. Get user from session
2. Check if tier === 'pro'
3. If free tier → return 402
4. Process request

### Phase 5: Frontend Components

**New components:**
```
components/
  PaywallModal.tsx     # "Upgrade to Pro" modal
  UsageBadge.tsx       # Shows "2/3 items today"
  PricingCard.tsx      # Pricing display
```

**New page:**
```
app/pricing/page.tsx   # Full pricing page
```

**Integration points in `app/page.tsx`:**
- Show UsageBadge in header
- Show PaywallModal when limit hit
- Disable architect for free users

### Phase 6: Stripe Webhook Handler

**`/api/stripe/webhook/route.ts` handles:**
- `checkout.session.completed` → Create subscription record
- `customer.subscription.updated` → Update tier/status
- `customer.subscription.deleted` → Downgrade to free

## Files to Create

| File | Purpose |
|------|---------|
| `lib/stripe/client.ts` | Browser Stripe loader |
| `lib/stripe/server.ts` | Server Stripe instance |
| `lib/subscription.ts` | Subscription check helpers |
| `app/api/stripe/checkout/route.ts` | Create checkout session |
| `app/api/stripe/portal/route.ts` | Customer portal redirect |
| `app/api/stripe/webhook/route.ts` | Webhook handler |
| `components/PaywallModal.tsx` | Upgrade prompt modal |
| `components/UsageBadge.tsx` | Usage counter display |
| `app/pricing/page.tsx` | Pricing page |

## Files to Modify

| File | Changes |
|------|---------|
| `app/api/summarize/route.ts` | Add auth + usage check |
| `app/api/architect/route.ts` | Add pro-only check |
| `app/page.tsx` | Add PaywallModal, UsageBadge |
| `context/AuthContext.tsx` | Add subscription state |
| `hooks/useQueue.ts` | Check limits before add |

## Verification

1. **Stripe Test Mode:**
   - Create test products/prices in Stripe Dashboard
   - Use test card 4242 4242 4242 4242
   - Verify webhook delivery with Stripe CLI

2. **Free Tier:**
   - Create new account
   - Add 3 items → should work
   - Add 4th item → PaywallModal appears
   - Architect button disabled/hidden

3. **Pro Tier:**
   - Complete Stripe checkout
   - Verify subscription record in Supabase
   - Unlimited items work
   - Architect enabled

4. **Subscription Management:**
   - Access customer portal
   - Cancel subscription
   - Verify downgrade to free tier
