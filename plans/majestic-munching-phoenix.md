# Payment Setup Plan for Focus First Learning App

## Overview
The payment code is already written using **Razorpay** (Indian payment provider). You need to set up external accounts and configure environment variables.

---

## Step-by-Step Setup (Start Here!)

### Step 1: Create Razorpay Account (5-10 mins)
1. Go to https://dashboard.razorpay.com
2. Click "Sign Up" and create an account with your email
3. **For testing**: You can start immediately in Test Mode (no KYC needed)
4. **For production**: Complete KYC verification later

### Step 2: Get Your API Keys
1. Log into Razorpay Dashboard
2. Look at the top-left - make sure "Test Mode" toggle is ON (orange)
3. Go to **Settings** (gear icon) → **API Keys**
4. Click **Generate Key** if you don't have one
5. **IMPORTANT**: Copy and save BOTH values immediately:
   - **Key ID**: `rzp_test_xxxxxxxxxxxx`
   - **Key Secret**: Only shown once! Save it now

### Step 3: Create a Subscription Plan
1. In Razorpay Dashboard, go to **Products** → **Plans**
2. Click **+ Create Plan**
3. Fill in:
   - **Plan Name**: "Focus First Pro" (or whatever you want)
   - **Billing Frequency**: Monthly
   - **Billing Cycles**: 1
   - **Amount**: Enter in paise (e.g., `29900` = ₹299, or `9900` = ₹99)
4. Click **Create**
5. Copy the **Plan ID** (looks like `plan_xxxxxxxxxxxxx`)

### Step 4: Run Database Migration (Do this now!)
1. Go to your Supabase Dashboard → **SQL Editor**
2. Copy the entire contents of `supabase/migrations/001_subscriptions.sql`
3. Paste it into the SQL Editor
4. Click **Run**
5. You should see "Success. No rows returned" - that's correct!

This creates:
- `user_subscriptions` table - tracks who is free vs pro
- `daily_usage` table - tracks daily limits
- Auto-trigger to give new users free tier

### Step 5: Get Supabase Service Role Key
1. Go to Supabase Dashboard → **Settings** → **API**
2. Find **service_role key** (under "Project API keys")
3. Copy it (this is secret - never expose in frontend!)

### Step 6: Set Environment Variables
Add ALL of these to your `.env.local` file:

```env
# Razorpay Keys (from Step 2)
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_key_secret_here
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx

# Razorpay Plan (from Step 3)
RAZORPAY_PLAN_ID=plan_xxxxxxxxxxxxx

# Webhook Secret (we'll set this in Step 7)
RAZORPAY_WEBHOOK_SECRET=placeholder_for_now

# Supabase Service Role (from Step 5)
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

### Step 7: Configure Webhook (Do this when deploying)
**Note**: Webhooks need a public URL, so do this when you deploy to Vercel/production.

1. In Razorpay Dashboard → **Settings** → **Webhooks**
2. Click **+ Add New Webhook**
3. Enter your URL: `https://your-app.vercel.app/api/razorpay/webhook`
4. Select these events:
   - `subscription.authenticated`
   - `subscription.activated`
   - `subscription.charged`
   - `subscription.cancelled`
5. Click **Create Webhook**
6. Copy the **Webhook Secret** and update your `.env` with `RAZORPAY_WEBHOOK_SECRET`

---

## What Each Part Does

| Component | Purpose |
|-----------|---------|
| `PaywallModal.tsx` | Shows upgrade prompt when user hits limits |
| `UsageBadge.tsx` | Shows "2/3" usage counter in the UI |
| `useSubscription.ts` | Hook to check if user can perform actions |
| `/api/razorpay/create-subscription` | Creates subscription when user upgrades |
| `/api/razorpay/webhook` | Receives payment confirmations from Razorpay |
| `/api/subscription/status` | Returns current user's tier and usage |

---

## Subscription Tiers

| Feature | Free | Pro |
|---------|------|-----|
| Summarizations/day | 3 | Unlimited |
| Items/day | 3 | Unlimited |
| Curriculum Architect | No | Yes |

---

## Testing Locally
1. Complete Steps 1-6 above
2. Restart your dev server: `npm run dev`
3. Create a new user account (or use existing)
4. Try to exceed the free tier limits
5. The PaywallModal should appear
6. Click "Upgrade to Pro" to test the Razorpay checkout
7. Use Razorpay test cards: `4111 1111 1111 1111` with any future expiry

---

## Quick Checklist
- [ ] Razorpay account created
- [ ] API Keys generated and saved
- [ ] Subscription plan created
- [ ] Database migration run in Supabase
- [ ] Service role key copied
- [ ] All env vars added to `.env.local`
- [ ] (When deploying) Webhook configured
