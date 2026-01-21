# Plan: Implement Supabase RLS with Clerk JWT Integration

## Goal
Add database-level Row Level Security (RLS) to enforce user data isolation, replacing the current application-level filtering that relies on the service role key (which bypasses RLS).

## Files to Modify

| File | Change |
|------|--------|
| `.env.local` | Add `NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| `lib/supabase.ts` | Add JWT-authenticated client factory |
| `lib/auth.ts` | **New file** - Clerk token helper |
| `app/api/prompts/route.ts` | Use new client, remove manual `user_id` filters |
| `app/api/categories/route.ts` | Use new client, remove manual `user_id` filters |
| `app/api/prompts/search/route.ts` | Use new client, remove `match_user_id` param |
| `app/api/prompts/backfill/route.ts` | Use new client, remove manual `user_id` filters |

## Implementation Steps

### Step 1: Clerk Dashboard - Create JWT Template
1. Go to Clerk Dashboard > **JWT Templates**
2. Create template named `supabase`
3. Use this configuration (signing key = Supabase JWT Secret):
```json
{
  "aud": "authenticated",
  "role": "authenticated",
  "user_id": "{{user.id}}"
}
```

### Step 2: Add Environment Variable
Add to `.env.local`:
```
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your_anon_key>
```

### Step 3: Update `lib/supabase.ts`
```typescript
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { requireEnv } from "@/lib/errors";

let serviceRoleClient: SupabaseClient | null = null;

// Service role client for admin operations (bypasses RLS)
export function getSupabaseServiceClient(): SupabaseClient {
  if (serviceRoleClient) return serviceRoleClient;
  const url = requireEnv("NEXT_PUBLIC_SUPABASE_URL");
  const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
  serviceRoleClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  return serviceRoleClient;
}

// Authenticated client for user operations (respects RLS)
export function getSupabaseClient(supabaseAccessToken: string): SupabaseClient {
  const url = requireEnv("NEXT_PUBLIC_SUPABASE_URL");
  const anonKey = requireEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY");
  return createClient(url, anonKey, {
    auth: { persistSession: false },
    global: {
      headers: { Authorization: `Bearer ${supabaseAccessToken}` },
    },
  });
}
```

### Step 4: Create `lib/auth.ts`
```typescript
import { auth } from "@clerk/nextjs/server";

export async function getSupabaseToken(): Promise<string | null> {
  const { getToken } = await auth();
  return await getToken({ template: "supabase" });
}

export async function requireSupabaseToken(): Promise<string> {
  const token = await getSupabaseToken();
  if (!token) throw new Error("Failed to get Supabase token");
  return token;
}
```

### Step 5: Supabase SQL - Enable RLS & Create Policies
Run in Supabase SQL Editor:
```sql
-- Enable RLS
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Prompts policies
CREATE POLICY "Users can view their own prompts" ON prompts FOR SELECT
  USING (auth.jwt() ->> 'user_id' = user_id);
CREATE POLICY "Users can insert their own prompts" ON prompts FOR INSERT
  WITH CHECK (auth.jwt() ->> 'user_id' = user_id);
CREATE POLICY "Users can update their own prompts" ON prompts FOR UPDATE
  USING (auth.jwt() ->> 'user_id' = user_id)
  WITH CHECK (auth.jwt() ->> 'user_id' = user_id);
CREATE POLICY "Users can delete their own prompts" ON prompts FOR DELETE
  USING (auth.jwt() ->> 'user_id' = user_id);

-- Categories policies
CREATE POLICY "Users can view their own categories" ON categories FOR SELECT
  USING (auth.jwt() ->> 'user_id' = user_id);
CREATE POLICY "Users can insert their own categories" ON categories FOR INSERT
  WITH CHECK (auth.jwt() ->> 'user_id' = user_id);
CREATE POLICY "Users can update their own categories" ON categories FOR UPDATE
  USING (auth.jwt() ->> 'user_id' = user_id)
  WITH CHECK (auth.jwt() ->> 'user_id' = user_id);
CREATE POLICY "Users can delete their own categories" ON categories FOR DELETE
  USING (auth.jwt() ->> 'user_id' = user_id);
```

### Step 6: Supabase SQL - Update `match_prompts` RPC
```sql
DROP FUNCTION IF EXISTS match_prompts(vector(1536), text, int, float);

CREATE OR REPLACE FUNCTION match_prompts(
  query_embedding vector(1536),
  match_count int DEFAULT 10,
  match_threshold float DEFAULT 0.5
)
RETURNS TABLE (
  id uuid, name text, content text, use_cases text,
  category_id uuid, created_at timestamptz, similarity float
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.name, p.content, p.use_cases, p.category_id, p.created_at,
         1 - (p.embedding <=> query_embedding) AS similarity
  FROM prompts p
  WHERE p.user_id = (auth.jwt() ->> 'user_id')
    AND p.embedding IS NOT NULL
    AND 1 - (p.embedding <=> query_embedding) > match_threshold
  ORDER BY p.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

### Step 7: Update API Routes

**Pattern for each route:**
```typescript
// Add import
import { requireSupabaseToken } from "@/lib/auth";

// In each handler, after auth check:
const supabaseToken = await requireSupabaseToken();
const supabase = getSupabaseClient(supabaseToken);

// Remove .eq("user_id", userId) from SELECT/UPDATE/DELETE queries
// Keep user_id in INSERT data (RLS validates it)
```

**Specific changes:**
- `app/api/prompts/route.ts`: Remove `.eq("user_id", userId)` from GET, PUT, DELETE
- `app/api/categories/route.ts`: Same pattern
- `app/api/prompts/search/route.ts`: Remove `match_user_id` parameter from RPC call
- `app/api/prompts/backfill/route.ts`: Remove `.eq("user_id", userId)`

## Testing Checklist
- [ ] User A cannot see User B's prompts
- [ ] Cannot insert with a different user_id
- [ ] Cannot update another user's records
- [ ] Cannot delete another user's records
- [ ] Vector search only returns current user's prompts

## Rollback Plan
```sql
ALTER TABLE prompts DISABLE ROW LEVEL SECURITY;
ALTER TABLE categories DISABLE ROW LEVEL SECURITY;
```
Then revert code changes to use service role key with manual filters.
