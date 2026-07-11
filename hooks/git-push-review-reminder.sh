#!/usr/bin/env bash
# Warn-only PreToolUse reminder — before pushing to origin main/master, run
# /code-review (or /security-review for sensitive diffs) on the diff first.
# Gated to `git push*` via the settings "if" filter. Never blocks: exit 0.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
# Allow args between `git` and `push` — `git -C <path> push` is 19% of pushes here, and the
# old strict `git[[:space:]]+push` gate silently dropped every one. (Caught in W28 review.)
printf '%s' "$cmd" | grep -qE '\bgit\b[^;|&]*[[:space:]]push\b' || exit 0
# fire when main/master is named, or on a bare push (current branch may be main)
if printf '%s' "$cmd" | grep -qE '\b(main|master)\b' \
   || printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]]*($|origin[[:space:]]*($|HEAD))'; then
  jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder: pushing to origin main/master. Per CLAUDE.md, run /code-review on the diff first (and /security-review if it touches auth, secrets, or user-supplied HTML) before this ships."}}'
fi
exit 0
