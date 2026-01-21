# Plan: Intent-Based Semantic Search (Phase 1 - Query Expansion)

## Problem
Current semantic search only matches word embeddings directly. When user searches "I am writing an essay for college", it won't find "Humanize content" prompt even though that prompt would help with the task.

## Solution: LLM Query Expansion
Before embedding the search query, use GPT-4o-mini to expand it with related terms that match what prompts the user might need.

**Example:**
```
Input: "I am writing an essay for college"
Expanded: "I am writing an essay for college. Related: humanize text, natural writing, academic writing, avoid AI detection, essay structure, college papers"
```

## Implementation

### Step 1: Create `lib/ai.ts`
New file with query expansion function:
```typescript
import OpenAI from "openai";

const openai = new OpenAI();

export async function expandSearchQuery(query: string): Promise<string> {
  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content: "You help expand search queries. Given a user's task/need, output 5-8 related keywords that describe prompts/tools they might need. Output only the keywords, comma-separated."
      },
      {
        role: "user",
        content: query
      }
    ],
    max_tokens: 100,
    temperature: 0.3,
  });

  const keywords = response.choices[0]?.message?.content || "";
  return `${query}. Related: ${keywords}`;
}
```

### Step 2: Update `app/api/prompts/search/route.ts`
Add query expansion before embedding:
```typescript
import { expandSearchQuery } from "@/lib/ai";

// Before generating embedding:
const expandedQuery = await expandSearchQuery(query.trim());
const queryEmbedding = await generateEmbedding(expandedQuery);
```

## Files to Modify/Create
1. `lib/ai.ts` (new) - Query expansion function
2. `app/api/prompts/search/route.ts` - Use expanded query

## Cost Estimate
- GPT-4o-mini: ~$0.15 per 1M input tokens
- Average query expansion: ~100 tokens = $0.000015 per search
- 1000 searches ≈ $0.015

## Future Phase 2 (Not Now)
- Add `use_cases` field to prompts
- Generate use cases when creating prompts
- Backfill existing prompts
- Include use_cases in embedding text
