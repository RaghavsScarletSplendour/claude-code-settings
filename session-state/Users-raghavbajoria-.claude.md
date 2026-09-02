---
updated: 2026-09-02T12:40:00Z
project: /Users/raghavbajoria/.claude
---

## Last done
Ran `/claude-api prompt-audit` over the whole `~/.claude` prompt surface (target model:
Claude Fable 5.1). Applied and pushed the fixes the user chose, in two commits on `main`:

1. H1/H3/H4/H5 — stop pasting the operating manual into every prompt (kept the
   SubagentStart injection); drop the "150 skills / 6%" trait claim and MANDATORY
   boosters from CLAUDE.md; plain verify-hook text; removed the dangling
   `claude-in-chrome` preflight bullet + hook (skill exists nowhere on this machine).
   **H2 (per-turn ASD-STE100 hook) kept on purpose — user prefers it.**
2. M1–M5, L1, L3 — 34 agent descriptions cut to intent-only, their fake-dialogue
   `<example>` blocks moved into a "## Examples (illustrative)" body section (the vendor
   frontmatter was already invalid YAML; now all 39 agents parse); deleted the two
   duplicate `agents/engineering/{frontend-developer,mobile-app-builder}.md` and the
   vendor `agents/README.md`; removed week-numbered retro archaeology from ci-babysit,
   subagent-hardening, weekly-retro, close-worktree, agent-spawn-rules, plan-only-guard;
   replaced two word-count caps; observer model now named by role (`ECC_OBSERVER_MODEL`);
   split `frontend-patterns` and `backend-patterns` SKILL.md into 8 `references/*.md`
   each with a 33-line index SKILL.md. L2 (conversation-mode formatting rule) left as-is.

Note: the five `agents/marketing/*` files besides app-store-optimizer and
tiktok-strategist have no frontmatter and are not loaded as agents (report overstated M1).

## In flight
Nothing.

## Next
1. Re-run `/claude-api prompt-audit` at the next model release; flagged-only items
   (L2) are re-checked then, not now.
2. Watch the first few sessions after these hooks change: replies should still lead
   with the verdict. If they slip, add one SessionStart reminder, not a per-turn one.
3. Carried over: `fix/pr-audit-staging-ci-signal` branch on jdjones-platform has no PR.

## Blockers
None.
