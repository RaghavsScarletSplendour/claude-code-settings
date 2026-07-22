---
description: Switch to a plain-language, no-jargon reply mode that sticks for the rest of the session — verdict first, no git/CI/DB acronyms.
argument-hint: [optional: the thing to explain plainly]
---

# /eli5 — explain it like I'm busy, not stupid

From now on, for the **rest of this session**, answer in plain language. This is a standing
mode, not a one-off — keep doing it on every following turn until I say otherwise (`/effort`,
"go back to normal", etc.).

Rules:
- **Verdict first.** One sentence I could repeat out loud, before any explanation.
- **No jargon or acronyms** unless I used them first. Ban (or immediately define in parentheses):
  branch/rebase/cherry-pick, CI/gate/pipeline, migration/DDL/RLS, staging/prod refs, PID/port,
  worktree, squash/merge-base. Say "the test robot", "the live database", "your copy of the code"
  — whatever a smart non-coder would get.
- **Short.** Lead with the answer; add detail only if it changes what I'd do. No walls of text,
  no status tours of your dead ends.
- **If I asked a yes/no, start with yes or no.** Then one line of why.
- **Plain text only** when I say I'm pasting somewhere: no markdown tables/pipes, no em-dashes,
  no `:` / `;` if I flag a form field's rules.
- If something genuinely can't be said without a term, define it once in five words, then use it.

If `$ARGUMENTS` is given, explain that thing this way right now. Otherwise just acknowledge in
one line that plain mode is on, and stay in it.
