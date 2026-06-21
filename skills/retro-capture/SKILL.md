---
name: retro-capture
description: >-
  Distill the CURRENT Claude Code session into a short, high-signal markdown
  digest and append it to this week's retro archive at
  ~/.claude/retro/<YYYY>-W<week>.md, focusing on where the work struggled. Use
  this whenever the user signals a session is wrapping up and wants it captured
  for later review — "capture this session", "we're done, log it", "save this
  for the retro", "the PR is merged, archive this", "write up this session", or
  before ending work they want a future retro to learn from. This is the
  producer half of the retro loop: it writes the clean digests that the
  weekly-retro skill later reads instead of raw JSONL. Always prefer capturing
  now, while the session is still in context — you are the cheapest, most
  accurate capturer there is, with no log to re-read and no second model to spin
  up.
---

# Retro Capture

## Why this exists

Raw Claude Code logs (JSONL) are long and noisy, so mining them later is
expensive and loses the struggle that's buried in tool-call spam. The fix is to
capture once, now, while the whole session is still in context — distill it to a
few lines of pure signal and append it to a weekly archive. Next week's
`weekly-retro` reads that clean archive instead of the raw logs, and every entry
points straight at a skill, hook, or tool worth building.

You already have this session in context. That makes capturing now far cheaper
and more accurate than re-reading a transcript after the fact.

## What to capture

Write only the signal. Most of a session is uneventful; skip it. Scan back over
the conversation following this prompt:

> Review this session. Write a short markdown digest with: (1) what we set out to
> do and whether it shipped, (2) the key decisions and final approach, and most
> importantly (3) every place we struggled — where we went back and forth to
> remove ambiguity, where a correction had to be repeated, where it took many
> attempts or heavy reasoning, or where a missing tool/skill/context cost time.
> Be specific and concise. Skip everything that went smoothly.

The struggle points are the whole point. Wherever you can, name the artifact that
would have prevented each one (a skill, a hook, an MCP tool, a reference doc) —
that's what makes the weekly retro's job trivial. If nothing genuinely struggled,
say so in one line rather than inventing friction; a retro built on manufactured
blockers is worse than a thin one.

## Entry format

Append one section per session, in the shape `weekly-retro` expects to read:

```markdown
## <YYYY-MM-DD> — <one-line title of what the session was about>
- Goal: <what we set out to do> — <Shipped ✅ / Partial / Didn't ship>
- Approach: <key decisions / final approach>
- Struggled:
  - <specific friction point> → missing: <skill/hook/tool/context that would fix it>
  - <next one, if any>
```

## Where it goes and how to append

One archive per ISO week, append-only, so the retro has a single clean file to
read. Compute the path and ensure the weekly file exists:

```bash
mkdir -p ~/.claude/retro
WEEK=$(date +%G-W%V)                 # ISO week-year, e.g. 2026-W25
ARCHIVE=~/.claude/retro/"$WEEK".md
[ -f "$ARCHIVE" ] || printf '# Retro archive — %s\n' "$WEEK" > "$ARCHIVE"
echo "$ARCHIVE"                       # the file to append your entry to
```

Then append your composed digest to that file with a plain append so earlier
sessions in the same week are never clobbered. Compose the entry yourself
(substituting today's real date and the actual content), then append it. Use a
**quoted** heredoc so any `$` or backticks in your notes are written literally
rather than run by the shell:

```bash
cat >> "$ARCHIVE" <<'EOF'

## 2026-06-21 — <title>
- Goal: ...
- Approach: ...
- Struggled:
  - ... → missing: ...
EOF
```

After writing, tell the user the exact path and show them the entry so they can
correct it while the context is still fresh.

## After capturing

This archive is the input to the `weekly-retro` skill. If the user hasn't set up
a regular retro, remind them once that the value compounds only if it runs on a
cadence — they can schedule it weekly so captured sessions actually get mined.

Keep digests local. They can contain private project detail, so they live under
`~/.claude/retro/` (gitignored) and should stay out of any synced or public repo.
