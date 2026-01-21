# Fix: Google OAuth Not Working

## Problem
Google Sign-In returns error:
```json
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}
```

Email/password login works fine.

## Root Cause
**This is a Supabase dashboard configuration issue, not a code issue.**

Google OAuth provider is not enabled in the Supabase project settings. The code in `context/AuthContext.tsx:86-98` correctly calls `signInWithOAuth({ provider: 'google' })`, but Supabase rejects it because the provider isn't configured on their end.

## Solution: Enable Google Provider in Supabase

### Step 1: Create Google OAuth Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Go to **APIs & Services > Credentials**
4. Click **Create Credentials > OAuth client ID**
5. Select **Web application**
6. Add authorized redirect URI: `https://<your-supabase-project>.supabase.co/auth/v1/callback`
7. Copy the **Client ID** and **Client Secret**

### Step 2: Enable Google in Supabase Dashboard
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Authentication > Providers**
4. Find **Google** in the list and click to expand
5. Toggle **Enable Sign in with Google** to ON
6. Paste your Google **Client ID** and **Client Secret**
7. Click **Save**

### Step 3: Configure Redirect URLs
In the Supabase dashboard under **Authentication > URL Configuration**:
- **Site URL**: `https://www.mindcueapp.com`
- **Redirect URLs**: Add `https://www.mindcueapp.com/auth/callback`

## Verification
After configuration:
1. Visit https://www.mindcueapp.com/app
2. Click "Continue with Google"
3. Should redirect to Google sign-in, then back to your app

## No Code Changes Required
The existing code is correct - this is purely a Supabase dashboard configuration task.
