# Global Guidance (Claude Code)

## Operating manual — read before every task

**Before starting any task, read `~/.claude/feedback_operating_manual.md` in full.** It is mandatory
operating guidance, not optional context: how to read requests, decompose work into checkable pieces,
allocate effort to risk, verify by re-deriving instead of trusting plausibility, label knowledge as
verified/inferred/assumed, attack your own conclusions before handing them over, and communicate
verdict-first. Apply the 5-question self-test at the end of it before sending any response. This
applies in every project, on every task, not just complex ones.

## Use the skills you have — reflexes that must fire without being asked

You have ~150 skills but reach for them ~6% of the time; the ones below carry a
*MANDATORY / PROACTIVE* intent that is otherwise inert (agents can't self-spawn and hooks
can't spawn agents, so honoring these is on you). Treat each as always-on, like the two
reflexes above — do it, then say you did.

- **Any chart / graph / dashboard / mockup / stat-tile / KPI code** — in *any* medium (HTML,
  React, inline SVG, matplotlib/plotly/d3/Recharts, an image to render) → invoke the `dataviz`
  skill *before the first line of chart code*; swap its palette for the brand palette before picking colors.
- **Committing a nontrivial change with a runtime surface, or any explicit "verify / test it in the
  browser / check the staging URL" request** → run the `verify` skill instead of hand-rolling E2E checks.
- **A commit/PR touching auth, permission gates, secret/env-key handling, or user-supplied-HTML
  rendering** → run a security pass (`security-auditor` agent or `/security-review`) and report findings.
- **`apply_migration` or a write `execute_sql` (INSERT/UPDATE/DELETE/DDL) against a production or
  shared DB** → spawn `database-reviewer` to review the statement *before* executing it.
- **Pushing nontrivial freshly-generated code to `origin/main`** → run `/code-review` on the diff first.
- **Authoring a Workflow or parallel-Agent fan-out** → apply `subagent-hardening` first (validate args
  actually bind → throw before fan-out; interpolate concrete values; permissive schemas; no trailing thinking block).
- **Any `mcp__claude-in-chrome__*` browser tool** → invoke the `claude-in-chrome` preflight skill first.
- **Authoring a NEW skill, or the user says "make this a skill" / "use skill-creator"** → route through
  the `skill-creator` skill (honoring an explicit request is mandatory). Not for one-line SKILL.md edits or copies.
- **Genuine competitor-comparison / fund-DD / "research this company" work** → invoke `market-research`
  for its collection checklist + source-attribution standard, then feed that into the Obsidian synthesis pipeline.

## Search first — don't reinvent what exists

**Before writing a custom utility, integration, or abstraction, check for an existing solution first** —
repo helper → stdlib → installed dependency → maintained library / MCP server / skill. Reach for custom
code only once that search comes up short, and say what you ruled out. For the full research workflow
(parallel registry/GitHub/MCP search, a decision matrix, adopt-vs-extend-vs-build), use the `search-first` skill.
