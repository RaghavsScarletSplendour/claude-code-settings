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

## Search first — don't reinvent what exists

**Before writing a custom utility, integration, or abstraction, check for an existing solution first** —
repo helper → stdlib → installed dependency → maintained library / MCP server / skill. Reach for custom
code only once that search comes up short, and say what you ruled out. For the full research workflow
(parallel registry/GitHub/MCP search, a decision matrix, adopt-vs-extend-vs-build), use the `search-first` skill.
