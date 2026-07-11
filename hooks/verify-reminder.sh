#!/usr/bin/env bash
# Warn-only PreToolUse reminder — before committing a change with a runtime surface,
# run the /verify skill (CLAUDE.md marks it MANDATORY; it fired 0 times in W27 and W28).
# Cloned from git-push-review-reminder.sh, the shape that moved database-reviewer 0 -> 10.
# Never blocks: exit 0.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
# Allow args between `git` and `commit` — `git -C <path> commit` is 18% of commits here, and
# a strict `git[[:space:]]+commit` gate silently dropped every one of them. (Caught in review.)
printf '%s' "$cmd" | grep -qE '\bgit\b[^;|&]*[[:space:]]commit\b' || exit 0

# Skip the noise: docs/test/config-only commits have no runtime surface to drive, and
# /verify explicitly says not to run on those. Cheapest reliable signal is the file set.
# The command may target another repo (`git -C <path> commit …` — 18% of commits here, the
# worktree pattern). Inspect THAT repo, not the shell's cwd, or the hook reads a clean tree
# and stays silent. (Caught in review.)
repo=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+("[^"]+"|'"'"'[^'"'"']+'"'"'|[^[:space:]]+).*/\1/p' | tr -d "\"'")
if [ -n "$repo" ] && [ -d "$repo" ]; then set -- -C "$repo"; else set --; fi

staged=$(git "$@" diff --cached --name-only 2>/dev/null)

# `git commit -a` / `--all` stages tracked modifications AT COMMIT TIME, so at PreToolUse
# the index is still empty and --cached returns nothing. Without this the hook is silent on
# the single most common commit form. (Caught in review; the first test suite missed it.)
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])(-[A-Za-z]*a[A-Za-z]*|--all)([[:space:]]|$)'; then
  staged=$(printf '%s\n%s' "$staged" "$(git "$@" diff --name-only HEAD 2>/dev/null)")
fi

staged=$(printf '%s' "$staged" | grep -v '^$' | sort -u)
[ -z "$staged" ] && exit 0

# Anything that is NOT a doc/test/lockfile counts as a runtime surface.
if printf '%s\n' "$staged" | grep -qvE '(^|/)(docs?|tests?|__tests__|e2e)/|\.(md|txt|lock|snap)$|(^|/)(package-lock\.json|pnpm-lock\.yaml|uv\.lock)$'; then
  jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder: this commit touches product source with a runtime surface. Per CLAUDE.md the /verify skill is MANDATORY here — drive the affected flow end-to-end and observe it, do not ship on tsc/vitest/build alone. (It has fired 0 times in the last two weeks while the user asked for verification by hand 27 times.)"}}'
fi
exit 0
