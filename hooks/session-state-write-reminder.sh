#!/usr/bin/env bash
# Warn-only PreToolUse reminder — at a ship boundary (push, PR create/merge), nudge
# to update the per-project session state file so the next session (or the next
# compaction) doesn't start from zero. Gated to matching commands via grep below.
# Never blocks: exit 0 always.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

printf '%s' "$cmd" | grep -qE '(\bgit\b[^;|&]*[[:space:]]push\b|\bgh[[:space:]]+pr[[:space:]]+(create|merge)\b)' || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
common=$(git rev-parse --git-common-dir 2>/dev/null)
top=$(git rev-parse --show-toplevel 2>/dev/null)
case "$common" in
  /*) mainrepo=$(dirname "$common") ;;
  *)  mainrepo=$(cd "$top" && cd "$(dirname "$common")" && pwd) ;;
esac
slug=$(printf '%s' "$mainrepo" | sed 's#^/##; s#/#-#g')
statefile="$HOME/.claude/session-state/${slug}.md"

jq -cn --arg sf "$statefile" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:("Ship boundary detected (push/PR). Before finishing this turn, write or update " + $sf + " — Last done / In flight / Next / Blockers, plus an `updated:` ISO-8601 UTC timestamp line. This is what the next session reads on resume.")}}'
exit 0
