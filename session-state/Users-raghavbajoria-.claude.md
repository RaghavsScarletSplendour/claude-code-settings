---
updated: 2026-09-02T13:10:00Z
project: /Users/raghavbajoria/.claude
---

## Last done
Ran `/code-review` (8 finder agents, high effort) on the two prompt-audit commits
(7b01e6a, 91c2073). 10 confirmed findings. Fixed and pushed the one the user asked
for:

- **Fixed (55efa8b):** the M1 description cleanup had mechanically stripped
  `PROACTIVELY` from 4 agent descriptions (whimsy-injector, experiment-tracker,
  project-shipper, studio-producer) — the audit guide explicitly says
  trigger/routing text may keep calibrated urgency, so this was cut in error.
  whimsy-injector had also lost its whole auto-trigger clause; restored.

Still open, not yet actioned (reported to user, no fix requested yet):
- An unrelated PotionLabs-specific `autoMode` block (soft_deny rules,
  trusted-repo declarations) rode into `settings.json` in commit 7b01e6a — it
  predates the prompt-audit and came from a concurrent session's uncommitted
  state; it is not reverted.
- `SubagentStart` still re-injects the full operating manual on every subagent
  spawn (kept on purpose — subagents lack the session's prior context — but
  CLAUDE.md's "read once per session" wording overstates the fix's scope).
- `skills/weekly-retro/SKILL.md:44` section heading still has a `(W28)` citation
  the body cleanup missed.
- `hooks/verify-reminder.sh:3` header comment is stale (says MANDATORY, cites
  W27/W28 firing rate) vs. the hook's own current emitted text at line 34.
- Two ASD-STE100 violations in text this session wrote: `CLAUDE.md:5-8`
  (one ~45-word/six-idea sentence) and `hooks/verify-reminder.sh:34`
  (~21-word sentence via semicolon).
- CLAUDE.md's verify bullet and verify-reminder.sh's text restate the same
  guidance independently (drift risk).
- The "These show the shape of a hand-off..." disclaimer is duplicated
  verbatim across all 33 rewritten agent files.
- `skills/backend-patterns/references/rate-limiting.md` is only 10 lines,
  smaller than its 47-114-line siblings.
## In flight
Nothing.

## Next
1. Wait for the user to say which of the 9 remaining code-review findings above
   to fix, if any — do not act on them unprompted.
2. Re-run `/claude-api prompt-audit` at the next model release; flagged-only items
   (L2) are re-checked then, not now.
2. Watch the first few sessions after these hooks change: replies should still lead
   with the verdict. If they slip, add one SessionStart reminder, not a per-turn one.
3. Carried over: `fix/pr-audit-staging-ci-signal` branch on jdjones-platform has no PR.

## Blockers
None.
