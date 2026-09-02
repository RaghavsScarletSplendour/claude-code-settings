---
name: subagent-hardening
description: >-
  Make multi-agent fan-out (Workflow scripts and parallel Agent spawns) reliable
  instead of silently corrupting work. Use whenever you are authoring a Workflow,
  spawning subagents in parallel, defining a StructuredOutput schema for agents, or
  debugging fan-out failures — "write a workflow", "fan out agents", "spawn
  subagents", "StructuredOutput rejected my call", "a reader returned null/nothing",
  "schema validation keeps failing", "final block cannot be thinking", "agent burned
  its retries", or "subagents read the wrong/stale files". It encodes the failure
  modes that repeatedly broke fan-out (invented-key schema rejections, trailing
  thinking-block 400s, lost-on-interrupt, undefined args reaching workers) and the
  concrete guards that prevent them. Also covers a SINGLE specialist Agent call
  (not a Workflow fan-out) that hangs or returns a shallow/wrong result — "a
  security-auditor call hung", "the specialist agent didn't come back", "how much
  do I trust one agent's review".
---

# Subagent / fan-out hardening

## Why this exists

Fan-out is the highest-leverage pattern available — and the most silently fragile.
The same handful of failures recur and corrupt results without an obvious error:

- **StructuredOutput rejection loops.** An agent invents a key not in the schema (or
  the schema is `additionalProperties:false`), the tool call is rejected, the agent
  retries, burns its retry cap, and returns **null / zero output** — so a fan-out
  quietly drops one worker's findings.
- **Trailing thinking / empty text → API 400.** "final block cannot be thinking" or
  "text content blocks must contain non-whitespace text" crashes a run mid-flight.
- **Lost-on-interrupt.** A long agent does all the work, then the run is interrupted
  *before* its final StructuredOutput call — all of it is lost.
- **Undefined args reaching workers.** A path/arg arrives `undefined`, so N spawned
  agents all read the wrong or stale file and confidently return garbage.

Most of these are preventable from the authoring side. This skill is the checklist.

## Guards you control

### 1. Inject a hardening preamble into every spawned agent
Prepend this to each subagent prompt (in a Workflow, build it once and concatenate):

```
OUTPUT CONTRACT — read before answering:
- Call the StructuredOutput tool FIRST, as soon as you have the answer; put any
  prose AFTER, never before. (An interrupt before the tool call loses your work.)
- Use ONLY the keys defined in the schema. If you cannot fill a field, return it
  empty ("" / [] / null) — do NOT invent new keys or rename them. The schema may be
  strict (additionalProperties:false); an unknown key rejects the whole call.
- Never emit an empty or whitespace-only text block, and never end your turn on a
  bare reasoning block — always finish with the tool call or real text.
- Your final tool output IS the return value (data, not a message to a human). No
  preamble, no apology, no markdown fences around the JSON.
```

### 2. Design schemas to DEGRADE, not reject
- Keep schemas as permissive as the task allows: minimal `required`, avoid
  `additionalProperties:false` unless you truly need it.
- Prefer arrays-of-objects with a few well-named fields over deeply nested shapes.
- Provide a **relaxed fallback schema**. If the strict call fails, retry once with a
  tiny schema so the worker yields *partial* output instead of nothing:

```js
// Workflow pattern: strict first, degrade to partial rather than lose the worker.
async function mine(prompt) {
  try { return await agent(prompt, { schema: STRICT }) }
  catch { return await agent(prompt + "\n\nReturn partial findings only.", { schema: FALLBACK }) }
}
const FALLBACK = { type:'object', properties:{ summary:{type:'string'}, items:{type:'array', items:{type:'object'}} }, required:['summary'] }
```

### 3. Emit structured output first (crash-safety)
The preamble already says this; it matters most for long/expensive agents. The result
exists the moment the tool call lands, so an interrupt afterward is harmless.

### 4. Fail fast on inputs BEFORE fan-out
Validate every required arg/path *before* spawning workers — a bad input multiplied by
N agents is N wasted (and misleading) results:

```js
if (!args?.targetPath) throw new Error('targetPath is required — refusing to fan out')
// optionally: confirm the path/glob actually resolves to files before mapping agents
```
Pass concrete, resolved values into each agent's prompt (interpolate the actual path),
not a variable the worker has to re-derive.

### 5. Handle dropped workers explicitly
`parallel()`/`pipeline()` return `null` for a worker that died or was skipped. Always
`.filter(Boolean)` before using results, and `log()` how many dropped — a silent
`.length` shrink reads as "nothing found" when it was really "3 workers crashed".

### 6. Sanitize history in any custom loop
If you build your own agent loop (not the Workflow tool): strip trailing thinking
blocks, never forward an empty/whitespace-only text block, and ensure the last block is
text or a tool call. (Inside the Workflow tool this is handled for you.)

### 7. Don't block synchronously on a single specialist agent
A single `Agent` call (e.g. `security-auditor`, `database-reviewer`) for one review
is a different failure mode than Workflow fan-out: it isn't dropped or corrupted, it
just sometimes hangs (retro W35/W36: a `security-auditor` call sat 10+ minutes with
no output, twice in one week). Agents run in the background by default for exactly
this reason — use that:

- If there's a manual fallback for the same check (reading the code yourself,
  reproducing the issue directly), don't wait synchronously. Launch the agent in the
  background, do the manual check in parallel, and only block on the agent's result
  if the manual check comes up empty or you specifically need the second opinion.
- If you *do* need to wait, give yourself a mental deadline (a few minutes for a
  focused review). Past that, proceed on the manual path and treat the agent's
  result as supplementary if it lands later — don't let a hung agent stall the turn.

### 8. One specialist pass is an opinion, not a verified fact — for anything security-critical, get a second one
A single review pass can be confidently wrong in a way that *looks* thorough: it
reports real-but-minor findings while missing the one that matters (retro W35/W36:
a `security-auditor` pass flagged two low-severity issues and missed that the same
script wrote unreviewed "confirmed" merges straight to the database). This isn't a
reason to skip the pass — it's a reason not to stop at one:
- For a security-sensitive change, don't treat one agent's clean report as the
  verdict. Either re-derive the specific findings yourself (rerun the exploit,
  re-read the diff line the finding cites) or get a second independent pass and
  compare, per the operating manual's "attack your own conclusion" step.
- This is cheap insurance, not redundant work: a same-session example is the
  worktree-preflight hook built during the 2026-W36 retro — a `security-auditor`
  pass found 3 real issues, each one was then independently re-verified with a
  direct test reproducing the exact evasion before being trusted or shipped.

## What is harness-level — report upstream, don't try to patch
These are not fixable from a skill/script; capture them in a bug report instead:
- StructuredOutput forwarding stray `</invoke>` / `</parameter>` fragments.
- Strict-schema rejection on invented keys consuming the full retry budget with no
  partial-output fallback.
- Work lost when a run is interrupted before the final tool call.

## Pre-flight checklist for any fan-out
- [ ] Required args validated; bad input throws before spawning.
- [ ] Concrete resolved values interpolated into prompts (no undefined paths).
- [ ] Hardening preamble prepended to every subagent prompt.
- [ ] Schema permissive; `required` minimal; fallback schema ready.
- [ ] Results `.filter(Boolean)`'d; dropped-worker count logged.
- [ ] Expensive agents told to emit StructuredOutput first.
