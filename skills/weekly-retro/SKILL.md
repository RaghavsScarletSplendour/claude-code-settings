---
name: weekly-retro
description: >-
  Review a window of your own past Claude Code sessions, find the recurring
  blockers — places where you burned thinking tokens, went back and forth to
  kill ambiguity, or re-explained the same thing — and generate the missing
  skills, hooks, MCP servers, or commands that would stop those blockers from
  happening again. Use this whenever the user wants a weekly/daily retro, asks
  "what slowed me down this week", "review my Claude Code history", "find my
  bottlenecks", "what skills am I missing", "mine my sessions", or wants the
  system to improve itself from past conversations. Treat past sessions as gold,
  not junk to be trashed.
---

# Weekly Retro

## Why this exists

Agents scale infinitely; you don't. The bottleneck is the human's attention, so
the goal is to tighten the loop — make next week's work cheaper by learning from
this week's friction. Every Claude Code session is saved locally, which means
your own history is training data for a smarter harness. A single review pass can
surface a pile of skills that, if you'd had them this week, would have made the
work faster, cleaner, and more reliable.

So the move is: periodically (end of week, or end of day) point an agent at the
record of how work actually went, find where it was hard, and **build the thing
that would have made it easy.** Don't try to remember to do this — make it a
repeatable pass.

## Inputs: finding the sessions

Claude Code stores each session's full conversation as a local JSONL file
(typically under `~/.claude/projects/<encoded-project-path>/*.jsonl`, one file
per session). Don't assume the path — discover it:

```bash
ls -dt ~/.claude/projects/*/ 2>/dev/null
find ~/.claude -name '*.jsonl' -mtime -7 2>/dev/null   # last 7 days
```

If that location is empty or different on this machine, ask the user where their
Claude Code history lives rather than guessing.

### Filter the corpus before you count anything (learned the hard way, W28)

The session directory contains sessions that are **not the human's work**, and they
outnumber the real ones. Filter both of these before any census, or every percentage
you report will be wrong:

- **The continuous-learning observer's own runs** — `~/.claude/projects/*ecc-homunculus*`.
  In W28 these were **259 of 338 sessions (3:1)**. They are Haiku `--print` runs, not work.
- **Injected skill/command preambles count as "user turns"** in the JSONL. A turn starting
  with `Base directory for this skill:`, `# /<command>`, `Review target:`, `<...>`, or
  `This session is being continued` is *not* something the human typed. In W28 this
  inflated 726 real turns → 1065, and made a correction-regex match skill docs instead of
  actual corrections.

Sanity-check the filter: if "sessions this week" is wildly higher than the number of days
× a plausible sessions-per-day, you are counting robots.

Two ways to read it:

1. **Distilled archive (preferred).** Raw JSONL is long and full of junk that
   isn't meant for human or AI consumption. If a weekly capture archive exists
   (a markdown digest written at the end of each session — see
   `references/session-capture-hook.md`), retro over that instead. It's clean,
   pre-highlighted for struggle points, and far cheaper to analyze.
2. **Raw JSONL directly.** Works, but noisy. Acceptable for a one-off. If you go
   this route, filter aggressively — pull user/assistant turns and ignore tool
   spam, large pasted blobs, and file dumps.

If no distilled archive exists yet, offer to set up the capture hook so future
retros are cheaper, then proceed against raw JSONL for this run.

## The retro pass

### 1. Scope the window

Default to the last 7 days. Confirm or adjust with the user. Collect the
sessions in range.

### 2. Extract friction signals

Read the sessions hunting specifically for where work was expensive, not where
it succeeded smoothly. The signals:

- Long back-and-forth to eliminate ambiguity before a task could be done right.
- The same correction made repeatedly across sessions ("no, use X not Y").
- The same context or explanation re-supplied that the agent should have known.
- Tasks that took many attempts, large reasoning effort, or repeated retries.
- Manual steps the human did by hand that an agent or tool could have owned.
- A missing capability the agent reached for and didn't have.

### 3. Cluster and rank the blockers

Group the signals into distinct blockers. Rank each by **frequency × cost** —
how often it recurred times how much it slowed things down. The top few are what
you fix; ignore the long tail.

### 4. Compute the delta for each blocker

For each top blocker, answer Proser's question: what's the delta? If you'd had
the right tool next time, how would the loop tighten? Decide which artifact fits:

- **Skill** — a recurring pattern, convention, or workflow the agent kept getting
  wrong or needed re-taught.
- **Hook** — something that should run automatically every session (a check, a
  capture, a guardrail).
- **MCP server / tool** — a repeated manual action against an external system
  (Slack, Linear, a database) that should be a callable tool.
- **Command** — a frequent multi-step invocation worth a shortcut.

### 5. Generate the artifacts

Hand the actual skill authoring to Claude Code's built-in skill-creation
capability, which can write, evaluate, and improve skills from a natural-language
description — don't hand-roll what it already does well. For each chosen artifact,
give it a tight spec: the blocker it kills, the trigger, and the expected
behavior. For hooks/MCP/commands, scaffold the config or stub and explain what to
wire up.

Do not silently install anything. The human is the director — present the
proposed artifacts for review and let them approve. Generating a bad skill that
fires constantly is worse than no skill.

### 6. Output

Produce a short retro report, then the artifacts:

```markdown
# Weekly Retro — <date range>

## Top blockers (ranked)
1. <blocker> — seen <N>× — cost: <why it hurt>
   → Proposed: <skill/hook/MCP/command> — <one line on how it tightens the loop>
2. ...

## Generated this run
- <artifact name> — <status: drafted / needs your review / installed>

## Skipped (low value)
- <blocker> — <why not worth an artifact yet>
```

Keep it honest: if a "blocker" only happened once, say so and don't manufacture a
skill for it. The aim is a system that gets measurably smarter each week, not a
pile of speculative skills.

## Make it recurring

The value compounds only if this runs regularly. Suggest the user schedule it —
a calendar reminder, a cron job, or a agent ready-style loop — so the retro
happens without anyone remembering to trigger it. Pair it with the session-end
capture hook in `references/session-capture-hook.md` so each future run reads a
clean archive instead of raw JSONL.
