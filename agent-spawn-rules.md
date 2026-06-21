# Agent-spawn house rules

Operating rules for when **I** spin up subagents / fan-out workflows. The retro found
that most wasted subagent effort traces to one thing: helpers aren't told the ground
rules, so they learn them the hard way every time. Prepend the relevant rules below to
each spawned agent's prompt (and follow them myself when orchestrating). Keep them
terse — they're a preamble, not an essay.

> Nothing project-specific or secret lives here — this file syncs with `~/.claude`.
> Project facts belong in that project's `.claude/`, never here.

## Put in the spawned agent's prompt

1. **Tools it actually has.** If the agent is read-only / plan-mode, say so plainly:
   *"You have no Write/Edit tool — do not search for one; your deliverable is your final
   message, inline."* This kills the recurring `ToolSearch select:Write` probe loop and
   the half-started Write that stalls. If it genuinely needs to write, give it a Write
   tool on purpose — don't let it discover the lack mid-run.

2. **Use the file tools, not the shell.** *"Use Glob to find files, Grep/ripgrep to
   search contents, Read to read them — do not shell out to `cat`/`find`/`grep -r`."*
   Shell search is slower, ignores `.gitignore`, and trips the zsh footguns (unquoted
   `--include` globs get mangled; short acronyms like `e.*way` false-match "always" —
   use word boundaries `\b`/`grep -w`).

3. **Strict-output contract (when using StructuredOutput / a schema).** Tell it: the
   **exact allowed keys** and that the schema is `additionalProperties: false` (extra or
   invented keys are rejected); **no literal `</invoke>` / `</parameter>` substrings in
   any field value** (they corrupt the tool call and trigger 5–10 retries); emit the
   structured call **once, as the final step, after a verifying Read** — not prematurely.

4. **Idempotency / don't redo work.** If an output file/brief may already exist, pass
   *"<path> may already exist — Read it and spot-check / extend it; don't re-extract from
   scratch,"* and tell it whether the brief is already complete. Saves a full redundant
   pass plus the Write-blocked-by-read-first churn.

## Keep on the orchestrator side (me)

5. **Dedupe the work-list before fanning out** — by **content/file hash**, not by slug.
   The same document under two names was dispatched (and interrupted) twice. One unit of
   work = one agent.

6. **Treat interrupts/socket flakes as transient** — retry once rather than dropping the
   item; where possible checkpoint partial output so a re-spawn resumes, not restarts.

7. **Ground them first.** Before fanning out over a codebase, build/inject a facts pack
   (e.g. this repo's `/map`) so siblings don't each re-derive the same basics.

8. **No silent caps.** If I bound coverage (top-N, sampling, no-retry), say what got
   dropped — don't let truncation read as "covered everything."
