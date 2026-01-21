# Plan: Fix "Failed to Process New Info" Error

## Problem Summary
User gets an error when trying to add any type of input while logged in. The error message is "failed to process new info" (or similar).

## Root Cause Analysis

There are **two potential error sources** in the code flow:

### Error Source 1: `/api/summarize` API Route
**File:** `app/api/summarize/route.ts`

The API can fail at several points:
- **Line 232:** Catch-all error returns `"Failed to process input. Please try again."`
- **Line 226:** JSON parse failure returns `"Failed to parse LLM response"`
- OpenAI API call failure (rate limiting, invalid key, network issues)

### Error Source 2: Supabase Database Insert (useQueue hook)
**File:** `hooks/useQueue.ts`

When logged in, `addItem()` inserts into Supabase (lines 182-200):
- If insert fails, `setError(insertError.message)` is called (line 192)
- Error is displayed via `queueError` in `page.tsx:225`

## Most Likely Cause
Since the error happens with **any input** and user is **logged in**, the issue is likely one of:

1. **OpenAI API Issue** - Key not set, invalid, or rate limited
2. **Supabase Insert Issue** - Database schema mismatch or permission error

## Debugging Steps

### Step 1: Check Network Tab
Have user check browser Network tab when submitting:
- Look for `/api/summarize` request
- Check status code (200 vs 500)
- Check response body for actual error message

### Step 2: Verify OpenAI API Key
Check if `OPENAI_API_KEY` is set in `.env.local`:
- If not set, code falls back to mock response (should work)
- If set but invalid, OpenAI call will fail

### Step 3: Check Supabase Table Schema
Verify `queue_items` table has all required columns matching `DatabaseQueueItem` interface:
- `id`, `user_id`, `raw_content`, `header`, `summary`, `status`
- `source_url`, `category`, `complexity_score`, `sequence_order`, `created_at`

## Proposed Fix

### Improve Error Visibility
Add better error logging to identify the exact failure point:

1. **In `app/api/summarize/route.ts`:**
   - Log the specific error type before returning generic message
   - Return more specific error messages

2. **In `hooks/useQueue.ts`:**
   - Log Supabase errors with more detail

3. **In `app/page.tsx`:**
   - Add console logging for debugging

## Files to Modify
- `app/api/summarize/route.ts` - Improve error handling/messages
- `hooks/useQueue.ts` - Add error logging for Supabase operations
- `app/page.tsx` - Add debug logging (optional)

## Verification
1. Run app locally with `npm run dev`
2. Try adding a link while logged in
3. Check browser console and Network tab
4. Verify the specific error source
5. Apply targeted fix based on findings
