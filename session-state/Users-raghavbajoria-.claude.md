---
updated: 2026-08-13T00:00:00Z
project: /Users/raghavbajoria/.claude
---

## Last done
Built a `UserPromptSubmit` hook that re-injects the ASD-STE100 (plain language) output
rule on every turn — `hooks/asd-ste100-reminder.sh`, wired into `settings.json`. This
fixes the problem where the CLAUDE.md instruction alone got ignored deep into long
conversations. Tested the script's raw JSON output directly; syntax-checked
`settings.json` with `jq -e`. Also added a matching "Plain language by default" section
to `CLAUDE.md` explaining ASD-STE100.

Checked off todo.md #3 (plain-language default) and confirmed #4/#4b (pr-audit changes,
done in an earlier session in a different repo) as already checked.

Committed (259b95d), then found this repo (`~/.claude`) and `origin/main` had diverged
(4 local commits vs 4 remote commits, common ancestor 7de422d). Fetched, merged with
`git pull --no-rebase` (clean auto-merge, no conflicts), then pushed. The push itself was
blocked twice by the auto-mode safety classifier when I tried it — user ran
`git push origin main` themselves via `!`, which succeeded (`df7487d..2e919eb`). Repo is
now 0 ahead / 0 behind.

Left untracked on purpose (matches prior session's read — local runtime state, not repo
content): `.DS_Store`, `.claude.json`, `daemon-auth-cooldown`, `daemon-auth-status.json`,
`policy-limits.json`, `skills/.DS_Store`, `supabase/`, `tmp/`.

## In flight
Nothing in progress.

## Next
Remaining open todo.md items: #5 (Railway CLI/MCP access — needs Raghav's environment,
not a repo change), #6 (permission allowlist for read-only prod verbs + `git worktree
remove` — todo.md flags this as loosening a security boundary, reads only, must not
drift into write verbs). No item picked yet; ask which one before starting.

## Blockers
The auto-mode classifier now blocks `git push origin main` from inside a Claude Code
turn in this repo (it did not block it in the 2026-08-03 session). Cause not verified —
possibly a policy change, possibly specific to this diff. User can push manually via `!
git push origin main` in the meantime. Worth confirming with the user whether this
should be added to the permission allowlist or left as a manual gate.
