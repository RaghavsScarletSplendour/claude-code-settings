# Global Guidance (Claude Code)

## Knowledge graph — think with the lattice

A personal knowledge graph of AI-product-building and mental-model insights lives at
`~/Projects/knowledge-graph/` (forked from ayushjj/knowledge-graph, `upstream` tracks his weekly additions).

**When making a non-trivial architectural, product, or strategic decision — or reviewing a plan —
read `~/Projects/knowledge-graph/graph-index.yaml` first** and check whether any insights bear on the
decision. That one file holds every node's title, description, topics, and links; read individual
`insights/*.md` files only when you need to go deeper on a specific node. Name the insights you drew on.

Grow the graph with these skills:
- `/learn <url | file | pasted text>` — extract atomic insights from a source and weave them in
- `/learn-book <pdf-path>` — process a book chapter by chapter
- `/connect` — find leaf nodes and add meaningful back-links

After adding insights, commit & push the fork; pull `upstream` periodically to merge Ayush's new insights.

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
