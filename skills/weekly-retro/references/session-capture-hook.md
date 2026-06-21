# Session-Capture Hook

Raw Claude Code JSONL logs are long, noisy, and not meant for consumption — so
mining them directly is expensive and lossy. The fix Proser suggests: at the end
of every session, distill the session into a short markdown digest and append it
to a weekly archive, highlighting where the work struggled. Then the weekly
retro reads the clean archive instead of raw JSONL.

This turns a giant pile of transcripts into a small, pre-curated record of what
actually mattered each week.

## When it fires

Trigger the capture at a natural session boundary — whichever your workflow uses:

- A Stop hook (end of a Claude Code session), or
- An explicit signal you give ("we're done", "the PR is merged").

## What it captures

The capture step is an AI prompt, not a deterministic dump. Instruct it to scan
the session and write only the signal:

> Review this session. Write a short markdown digest with: (1) what we set out to
> do and whether it shipped, (2) the key decisions and final approach, and most
> importantly (3) every place we struggled — where we went back and forth to
> remove ambiguity, where a correction had to be repeated, where it took many
> attempts or heavy reasoning, or where a missing tool/skill/context cost time.
> Be specific and concise. Skip everything that went smoothly.

## Where it goes

Append to a single archive per week so the retro has one clean file to read:

```
~/.claude/retro/<YYYY>-W<week>.md
```

A flat markdown file, an Obsidian note, or any simple archive works — the only
requirement is that it's clean, append-only, and groups a week together.

## Example digest entry

```markdown
## 2026-06-18 — fix sentence-case enforcer mangling acronyms
- Goal: stop the casing pass from breaking SKIM / SSO. Shipped ✅
- Approach: added an acronym allowlist checked before recasing.
- Struggled:
  - Took 3 rounds to realize the agent didn't know which tokens were acronyms —
    had to re-explain the domain each time. → missing: an acronyms reference.
  - Re-ran the blogbot flow manually 4× to verify; no automated check. → missing:
    a functional verification step / hook.
```

That entry alone tells next week's retro exactly two skills worth building — an
acronyms reference and a verification hook — without re-reading a single raw
JSONL line.

## Why distill instead of pointing at JSONL

Pointing the retro straight at raw JSONL does work for a one-off, but it pays the
noise tax every time and can miss struggle that's buried in tool-call spam. The
hook moves that cost to once-per-session, when the context is fresh, and leaves
you a durable, high-signal record. Treat each session as gold — capture it before
it's gone.
