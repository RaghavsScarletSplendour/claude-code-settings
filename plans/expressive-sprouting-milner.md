# Semantic Search Feature Implementation Plan

## Overview
Add semantic search capability to the Prompt Bank app. Users can describe their desired task in natural language, and the app will find the best matching prompts using OpenAI embeddings and vector similarity search.

## Tech Choices
- **AI Provider**: OpenAI (text-embedding-3-small)
- **Approach**: Embeddings-based vector search via Supabase pgvector
- **UI**: Toggle between text search and semantic search on existing `/search` page

---

## Implementation Steps

### Phase 1: Database Setup (Supabase SQL Editor)

Run these SQL commands in Supabase:

```sql
-- 1. Enable pgvector extension
create extension if not exists vector;

-- 2. Add embedding column (1536 dimensions for text-embedding-3-small)
alter table prompts add column embedding vector(1536);

-- 3. Create index for fast similarity search
create index on prompts using ivfflat (embedding vector_cosine_ops) with (lists = 100);

-- 4. Create similarity search function
create or replace function match_prompts (
  query_embedding vector(1536),
  match_user_id text,
  match_count int default 10,
  match_threshold float default 0.3
)
returns table (
  id uuid,
  name text,
  content text,
  tags text,
  created_at timestamptz,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    prompts.id,
    prompts.name,
    prompts.content,
    prompts.tags,
    prompts.created_at,
    1 - (prompts.embedding <=> query_embedding) as similarity
  from prompts
  where prompts.user_id = match_user_id
    and prompts.embedding is not null
    and 1 - (prompts.embedding <=> query_embedding) > match_threshold
  order by prompts.embedding <=> query_embedding
  limit match_count;
end;
$$;
```

### Phase 2: Environment Setup

Add to `.env.local`:
```
OPENAI_API_KEY=sk-...
```

### Phase 3: Backend Changes

#### 3.1 Install OpenAI package
```bash
npm install openai
```

#### 3.2 Create embedding utility
**New file**: `lib/embeddings.ts`
- `generateEmbedding(text)` - calls OpenAI API
- `getEmbeddingText(name, content, tags)` - combines prompt fields

#### 3.3 Modify prompt CRUD routes
**File**: `app/api/prompts/route.ts`
- POST: Generate embedding when creating prompt
- PUT: Regenerate embedding when updating prompt
- Graceful degradation: if embedding fails, save prompt without it

#### 3.4 Create semantic search endpoint
**New file**: `app/api/prompts/search/route.ts`
- POST endpoint accepting `{ query, limit }`
- Generates embedding for query
- Calls `match_prompts` RPC function
- Returns prompts with similarity scores

### Phase 4: Frontend Changes

#### 4.1 Update types
**File**: `lib/types.ts`
- Add optional `similarity?: number` to Prompt interface

#### 4.2 Enhance search page
**File**: `app/search/page.tsx`
- Add toggle: "Text Search" | "Semantic Search"
- Text mode: existing local filter by name
- Semantic mode: debounced API call to `/api/prompts/search`
- Different placeholder text for semantic mode

#### 4.3 Display similarity scores
**Files**: `components/PromptGallery.tsx`, `components/PromptCard.tsx`
- Add `showSimilarity` prop
- Show "X% match" badge when in semantic mode

### Phase 5: Backfill Existing Prompts

**New file**: `scripts/backfill-embeddings.ts`
- One-time script to generate embeddings for existing prompts
- Run with: `npx tsx scripts/backfill-embeddings.ts`

---

## Files to Modify/Create

| File | Action |
|------|--------|
| `.env.local` | Add OPENAI_API_KEY |
| `lib/embeddings.ts` | Create (new) |
| `lib/types.ts` | Modify (add similarity) |
| `app/api/prompts/route.ts` | Modify (add embedding generation) |
| `app/api/prompts/search/route.ts` | Create (new) |
| `app/search/page.tsx` | Modify (add semantic mode) |
| `components/PromptGallery.tsx` | Modify (pass showSimilarity) |
| `components/PromptCard.tsx` | Modify (display similarity badge) |
| `scripts/backfill-embeddings.ts` | Create (new, one-time use) |

---

## Cost Estimate
- text-embedding-3-small: $0.02 per 1M tokens
- ~100 tokens per prompt → 1000 prompts costs ~$0.002
- Minimal ongoing cost for searches
