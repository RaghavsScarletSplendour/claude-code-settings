---
name: brand-name-preflight
description: >-
  Pick a company/product name that is actually available BEFORE any branding,
  domain purchase, deploy, or DNS happens. Use whenever the task is "find a
  company/product name", "name ideas", "rebrand", "pick a name", or you're about to
  buy a domain / build a landing page / set up DNS for a new brand. It kills two
  expensive patterns: a full site getting built + deployed + DNS'd + search-console
  submitted before discovering the name was taken (forcing a total rebrand unwind),
  and giant 25-agent / ~900k-token name-generation fan-outs whose output gets
  rejected wholesale. The flow is the opposite: ONE small taste-driven shortlist,
  then a cheap multi-channel availability gate, returning only vetted survivors —
  and a hard rule that nothing downstream (branding/deploy/DNS) starts until a name
  clears.
---

# Brand-name preflight

## Why this exists

Two failure modes, both costly:
1. **Collision found too late.** The name gets locked in, the site is built,
   deployed, DNS'd, sitemap submitted — *then* "that name is taken." Everything
   (schema, OG images, llms.txt, domain, copy) has to be unwound.
2. **Generate-then-reject churn.** Spinning up dozens of subagents to brainstorm
   hundreds of names burns a fortune and the whole batch gets dismissed ("these
   names suck"), because taste wasn't pinned first and nothing was pre-filtered for
   availability.

Fix: **taste first (small), availability gate second (cheap), hard-gate downstream.**

## The rule

> **No branding, domain purchase, landing page, deploy, or DNS until a name passes
> the availability gate below.** Surface collisions at hour zero, not post-launch.

## Step 1 — Pin the taste rubric (before generating anything)

Ask the user (or infer + confirm) the constraints, so generation is targeted not
scattershot:
- positioning / what it must evoke; tone (serious vs playful); length (≤ ~10 chars
  reads best); pronounceable + spellable on first hear; not a near-homophone of a
  competitor; TLD intent (`.com` vs `.ai` vs other); any words to avoid.

## Step 2 — One small shortlist (NOT a mega fan-out)

Generate **~8–15 candidates in a single pass** against the rubric. Do not spawn a
large agent fleet — one focused pass, then iterate only if the gate kills too many.
Group by naming strategy (coined, compound, metaphor, real-word) so the user can
react to directions, not just names.

## Step 3 — The availability gate (cheap, multi-channel)

Run every candidate through these checks; **drop any that fails a hard channel.**

- **Domain.** Use the Vercel MCP tool
  `mcp__plugin_vercel_vercel__check_domain_availability_and_price` for the intended
  TLD(s) (`.com` and `.ai` at minimum). Cross-check with an RDAP/whois lookup via
  WebFetch (`https://rdap.org/domain/<name>.com`) — RDAP "not found" ≈ available;
  a registered record ≈ taken. (Domain = hard channel.)
- **Trademark / company-registry sanity.** Web-search the bare name + the name +
  the sector. Key principle: **trademark protection is per class** — a mark used in
  one class (e.g. retail/Class 35) does not necessarily block use in another (e.g.
  software/Class 9/42), so judge collisions *within the relevant class*, not
  globally. Also check the local company registry if a legal entity is implied.
- **Social handles.** Check the primary platforms the brand will use (X, Instagram,
  LinkedIn, GitHub) via WebFetch of the public profile URL — a 404 ≈ handle free.
  (Soft channel: a taken handle is a downgrade, not always a kill.)
- **Search-collision / SEO.** A quick search: does an established product/company
  already own the first page for this exact term? If yes, downgrade.

## Step 4 — Return only vetted survivors

Present a short table: candidate · `.com`/`.ai` status (+ price) · trademark-class
read · handle availability · search-collision · **verdict (clear / risky / dead)**.
Recommend from the *clear* set. If none clear, loop back to Step 2 with what the
gate taught you — never hand back names that haven't passed.

## Distinctions worth stating
- **Brand name ≠ legal entity name.** The trading/brand name and the registered
  company name can differ; a clash on one isn't always a clash on the other —
  evaluate them separately.
- **Available domain ≠ clear trademark**, and vice-versa. Both channels matter; a
  free `.com` with an in-class trademark conflict is still a dead name.

## Guardrails
- Keep generation cheap — one pass, small set. Escalate breadth only if the gate
  rejects everything.
- The gate is **advisory on law, not a legal opinion** — for anything high-stakes,
  recommend a real trademark attorney before filing/printing.
- Re-state the hard rule whenever someone wants to start building before a name
  clears: **preflight first.**
