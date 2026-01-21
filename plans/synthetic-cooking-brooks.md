# Plan: Phase 2 - Database Migration

## Overview
Migrate from localStorage to Supabase database for cross-device sync.

**Phase 1 (Auth)**: COMPLETE
**Phase 2 (Database)**: IN PROGRESS

---

## Phase 1: Authentication (COMPLETE)

### Dependencies to Install
```bash
npm install @supabase/supabase-js @supabase/ssr
```

### Files to Create

| File | Purpose |
|------|---------|
| `lib/supabase/client.ts` | Browser Supabase client |
| `lib/supabase/server.ts` | Server-side Supabase client |
| `lib/supabase/middleware.ts` | Session refresh middleware |
| `context/AuthContext.tsx` | Auth state provider + useAuth hook |
| `components/AuthModal.tsx` | Login/signup modal UI |
| `app/auth/callback/route.ts` | OAuth callback handler |

### Files to Modify

| File | Changes |
|------|---------|
| `app/layout.tsx` | Wrap with AuthProvider |
| `app/page.tsx` | Add login button, show user state |
| `middleware.ts` | Create for session refresh |
| `.env.local` | Add `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` |

### Auth Features
- Email/password signup & login
- Google OAuth (configure in Supabase dashboard)
- Session persistence across tabs
- Sign out functionality

---

## Phase 2: Database Migration (CURRENT)

### Pre-requisite: Run SQL in Supabase
User must run this SQL in Supabase SQL Editor first:

```sql
CREATE TABLE queue_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  raw_content TEXT NOT NULL,
  header TEXT NOT NULL,
  summary TEXT NOT NULL,
  status TEXT DEFAULT 'queued',
  source_url TEXT,
  category TEXT,
  complexity_score INTEGER,
  sequence_order INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE archive_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  header TEXT NOT NULL,
  summary TEXT NOT NULL,
  source_url TEXT,
  learned_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE queue_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE archive_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own queue items"
  ON queue_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage own archive items"
  ON archive_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Files to Create

| File | Purpose |
|------|---------|
| `hooks/useQueue.ts` | Queue CRUD with dual-mode (Supabase + localStorage fallback) |
| `hooks/useArchive.ts` | Archive CRUD with dual-mode |

### `hooks/useQueue.ts` - Key Features
- Fetches queue from Supabase when logged in, localStorage when not
- CRUD: `addItem`, `removeItem`, `updateItem`, `reorderQueue`
- Converts camelCase ↔ snake_case for database
- Migrates localStorage → Supabase on first login
- Orders by `sequence_order`, then `created_at`

### `hooks/useArchive.ts` - Key Features
- Same dual-mode pattern as useQueue
- CRUD: `addToArchive`, `removeFromArchive`
- Respects MAX_ARCHIVE_ITEMS (50) limit

### Files to Modify

| File | Changes |
|------|---------|
| `app/page.tsx` | Replace localStorage with hooks, handle async operations |

### Migration Strategy
1. Track migration per-user with `signal_queue_migrated_{userId}` key
2. On login, check if migration needed
3. Insert localStorage data to Supabase
4. Clear localStorage after successful migration
5. Only runs once per user

### Unauthenticated Users
- App works without login using localStorage (existing behavior)
- "Sign in to sync" prompt (non-blocking)
- Data auto-migrates when user logs in

---

## Supabase Setup (Manual Steps)
1. Create project at supabase.com
2. Get URL and anon key from Settings → API
3. Add to `.env.local`
4. Enable Google OAuth in Authentication → Providers
5. Run SQL schema in SQL Editor

---

## Verification

### Phase 1 (Auth)
1. Run `npm run dev`
2. Click login → sign up with email
3. Check email for confirmation
4. Sign in → verify user state shown
5. Refresh page → verify session persists
6. Sign out → verify state cleared

### Phase 2 (Database)
1. Add items to queue → verify saved in Supabase
2. Mark as learned → verify moved to archive
3. Open in incognito (same account) → verify data syncs
4. Sign out → verify data inaccessible
5. Test localStorage migration flow

---

## File Summary

**Create (8 files):**
- `lib/supabase/client.ts`
- `lib/supabase/server.ts`
- `lib/supabase/middleware.ts`
- `context/AuthContext.tsx`
- `components/AuthModal.tsx`
- `app/auth/callback/route.ts`
- `hooks/useQueue.ts`
- `hooks/useArchive.ts`

**Modify (5 files):**
- `app/layout.tsx`
- `app/page.tsx`
- `middleware.ts` (create)
- `types/index.ts`
- `.env.local`
