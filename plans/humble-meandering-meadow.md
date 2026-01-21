# Plan: Improve Use Case Generation Prompt

## Goal
Improve the prompt in `lib/ai.ts:29-32` that generates use cases for semantic search matching.

## Current Problems
- Search misses: relevant prompts don't surface for user queries
- Not enough variety: use cases are too similar to each other
- Need to match task descriptions like "writing a cover letter"

## Current Prompt
```
You analyze prompts and generate use cases. Given a prompt's name and content, output 5-8 specific use cases describing when/why someone would use this prompt. Output only the use cases, comma-separated, no explanation.
```

## Proposed New Prompt
```
You generate search-optimized use cases for a prompt library. Given a prompt's name and content, generate 8-10 diverse task descriptions that someone might search when they need this prompt.

Include variety across:
- Specific tasks (e.g., "writing a cover letter for a tech job")
- General tasks (e.g., "improving my writing")
- Different contexts (work, school, personal)
- Different phrasings of the same need

Output only the use cases, comma-separated, no explanation.
```

## Key Changes
1. **Increased count**: 5-8 → 8-10 (more coverage)
2. **Task-focused language**: "task descriptions someone might search" vs "when/why someone would use"
3. **Explicit variety guidance**: specific vs general, different contexts, different phrasings
4. **Search-optimized framing**: primes the model to think about discoverability

## File to Modify
- `lib/ai.ts` lines 29-32 (system prompt)
- Optionally: increase `max_tokens` from 150 → 200 to accommodate more use cases

## Testing
After change, can test by:
1. Creating a new prompt and checking generated use cases
2. Comparing variety/coverage vs old approach
