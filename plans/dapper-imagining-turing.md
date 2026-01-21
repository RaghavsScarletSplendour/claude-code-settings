# Razorpay Setup Guide for Focus First

## Environment Variables

Add these to your `.env.local`:

```bash
RAZORPAY_KEY_ID=rzp_test_xxxxx
RAZORPAY_KEY_SECRET=your_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
RAZORPAY_PLAN_ID=plan_xxxxx
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_xxxxx
```

---

## Razorpay Dashboard Setup

### Step 1: Get API Credentials
1. Go to **Dashboard → Settings → API Keys**
2. Generate a new key pair (use Test mode first)
3. Copy Key ID → `RAZORPAY_KEY_ID` and `NEXT_PUBLIC_RAZORPAY_KEY_ID`
4. Copy Secret → `RAZORPAY_KEY_SECRET`

### Step 2: Create a Subscription Plan
1. Go to **Dashboard → Plans → Create Plan**
2. Set price: ₹500/month (or your chosen price)
3. Set billing cycle: Monthly
4. Copy the Plan ID (starts with `plan_`) → `RAZORPAY_PLAN_ID`

### Step 3: Set Up Webhook
1. Go to **Dashboard → Settings → Webhooks → Add New Webhook**
2. URL: `https://your-domain.com/api/razorpay/webhook`
3. Select these events:
   - `subscription.authenticated`
   - `subscription.activated`
   - `subscription.charged`
   - `subscription.pending`
   - `subscription.halted`
   - `subscription.cancelled`
4. Copy the Webhook Secret → `RAZORPAY_WEBHOOK_SECRET`

---

## Database Tables Required

Ensure these exist in Supabase:

### `user_subscriptions`
- `id` (UUID, primary key)
- `user_id` (UUID, unique FK to auth.users)
- `razorpay_customer_id` (TEXT)
- `razorpay_subscription_id` (TEXT)
- `tier` (TEXT) - 'free' or 'pro'
- `status` (TEXT) - active, authenticated, pending, halted, cancelled, completed, expired
- `current_period_end` (TIMESTAMPTZ)
- `created_at`, `updated_at` (TIMESTAMPTZ)

### `daily_usage`
- `id` (UUID, primary key)
- `user_id` (UUID, FK to auth.users)
- `date` (DATE)
- `summarizations` (INT)
- `items_created` (INT)
- UNIQUE constraint on (user_id, date)

### Trigger
- `on_auth_user_created_subscription` - auto-creates free tier for new users

---

## Local Testing

For webhook testing locally:
```bash
ngrok http 3000
```
Use the ngrok URL in Razorpay webhook settings.

---

## Pricing Analysis

### GPT-4o-mini Costs

| | Per 1M tokens | Per 1K tokens |
|---|---|---|
| Input | $0.15 | $0.00015 |
| Output | $0.60 | $0.0006 |

### Cost Per API Call

**Summarize:** ~$0.00048/call (~₹0.04)
- Input: ~2,370 tokens (system + content + header)
- Output: ~200 tokens

**Architect:** ~$0.00093/call (~₹0.08)
- Input: ~2,210 tokens (system + queue data + header)
- Output: ~1,000 tokens

### User Scenarios at ₹500/month

| User Type | Usage | API Cost | Profit | Margin |
|---|---|---|---|---|
| Light | 10 items/day, 5 days | ₹6 | ₹494 | 98.8% |
| Regular | 10 items/day, 30 days | ₹35 | ₹465 | 93% |
| Heavy | 50 items/day, 30 days | ₹175 | ₹325 | 65% |

### Conclusion

**₹500/month is highly profitable.** Even extreme power users only cost ~₹175 in API credits. You could charge as low as ₹199-299 and still be profitable, but ₹500 provides buffer for:
- Infrastructure (Supabase, Vercel, domain)
- Future AI feature additions
- Marketing/growth costs

---

## Tier Limits (Already Configured)

**Free Tier:**
- 3 summarizations/day
- 3 items/day
- No Architect AI

**Pro Tier:**
- Unlimited summarizations
- Unlimited items
- Architect AI enabled
