# Prompt Bank - Implementation Plan

## Overview
A simple prompt bank app with Next.js, Tailwind CSS, Clerk.js (auth), and Supabase (database).

## Project Structure (Minimal - ~12 files)
```
prompt-bank/
├── app/
│   ├── layout.tsx              # ClerkProvider wrapper
│   ├── page.tsx                # Home page (prompts gallery + add button)
│   ├── sign-in/[[...sign-in]]/page.tsx
│   └── api/prompts/route.ts    # Single API route (GET/POST)
├── components/
│   ├── PromptCard.tsx          # Single prompt display
│   ├── PromptForm.tsx          # Modal form to add prompt
│   ├── PromptGallery.tsx       # Grid of prompts
│   └── UserMenu.tsx            # User avatar + logout
├── lib/
│   └── supabase.ts             # Supabase client
├── middleware.ts               # Clerk route protection
└── .env.local                  # Environment variables
```

## Database Schema (Supabase)
```sql
CREATE TABLE prompts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  tags TEXT,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_prompts_user_id ON prompts(user_id);
```

## API Endpoints
Single file `/api/prompts/route.ts`:
- **GET**: Fetch all prompts for current user
- **POST**: Create new prompt (name, tags, content)

## Implementation Steps

### Phase 1: Project Setup
- [ ] Initialize Next.js with TypeScript + Tailwind
- [ ] Install `@clerk/nextjs` and `@supabase/supabase-js`
- [ ] Create `.env.local` with Clerk + Supabase keys

### Phase 2: Authentication (Clerk)
- [ ] Create `middleware.ts` for route protection
- [ ] Update `app/layout.tsx` with ClerkProvider
- [ ] Create sign-in page

### Phase 3: Database (Supabase)
- [ ] Create `prompts` table in Supabase dashboard
- [ ] Create `lib/supabase.ts` client

### Phase 4: API Layer
- [ ] Create `app/api/prompts/route.ts` with GET/POST

### Phase 5: UI Components
- [ ] Create `UserMenu.tsx` (avatar + logout)
- [ ] Create `PromptCard.tsx` (display prompt)
- [ ] Create `PromptGallery.tsx` (grid layout)
- [ ] Create `PromptForm.tsx` (modal form)

### Phase 6: Home Page
- [ ] Build `app/page.tsx` with header, add button, and gallery

### Phase 7: Testing
- [ ] Test full flow: sign in -> add prompt -> view gallery -> logout

## Critical Files
1. `/middleware.ts` - Route protection
2. `/app/api/prompts/route.ts` - API logic (Clerk + Supabase)
3. `/app/page.tsx` - Main home page
4. `/components/PromptForm.tsx` - Add prompt modal
5. `/lib/supabase.ts` - Database client
