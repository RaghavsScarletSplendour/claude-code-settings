#!/usr/bin/env bash
# Warn-only PreToolUse reminder — before committing a change with a runtime surface,
# run the /verify skill (CLAUDE.md marks it MANDATORY; it fired 0 times in W27 and W28).
# Cloned from git-push-review-reminder.sh, the shape that moved database-reviewer 0 -> 10.
# Never blocks: exit 0.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
printf '%s' "$cmd" | grep -qE '\bgit[[:space:]]+commit\b' || exit 0

# Skip the noise: docs/test/config-only commits have no runtime surface to drive, and
# /verify explicitly says not to run on those. Cheapest reliable signal is the staged set.
staged=$(git diff --cached --name-only 2>/dev/null)
[ -z "$staged" ] && exit 0

# Anything that is NOT a doc/test/lockfile counts as a runtime surface.
if printf '%s\n' "$staged" | grep -qvE '(^|/)(docs?|tests?|__tests__|e2e)/|\.(md|txt|lock|snap)$|(^|/)(package-lock\.json|pnpm-lock\.yaml|uv\.lock)$'; then
  jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder: this commit touches product source with a runtime surface. Per CLAUDE.md the /verify skill is MANDATORY here — drive the affected flow end-to-end and observe it, do not ship on tsc/vitest/build alone. (It has fired 0 times in the last two weeks while the user asked for verification by hand 27 times.)"}}'
fi
exit 0
