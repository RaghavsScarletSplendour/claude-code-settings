#!/usr/bin/env bash
# SessionStart hook — read the durable per-project state file (if one exists) and
# inject it so "what's next" is a file read instead of an archaeology pass.
# Keyed on the MAIN repo (git-common-dir), not the current worktree — with ~12 live
# worktrees, keying on toplevel would make state written in one tree invisible from
# another. Retro W30-31, blocker #1: state loss, 14/14 sessions.
# Never blocks: exit 0 always. Silent outside a git repo or with no state file yet.
set -uo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

common=$(git rev-parse --git-common-dir 2>/dev/null)
top=$(git rev-parse --show-toplevel 2>/dev/null)
case "$common" in
  /*) mainrepo=$(dirname "$common") ;;
  *)  mainrepo=$(cd "$top" && cd "$(dirname "$common")" && pwd) ;;
esac

slug=$(printf '%s' "$mainrepo" | sed 's#^/##; s#/#-#g')
statefile="$HOME/.claude/session-state/${slug}.md"

[ -f "$statefile" ] || exit 0

input=$(cat 2>/dev/null || true)
source=$(printf '%s' "$input" | jq -r '.source // ""' 2>/dev/null)

body=$(cat "$statefile")

updated_line=$(grep -m1 '^updated:' "$statefile" 2>/dev/null | sed 's/^updated: *//')
age_note=""
if [ -n "$updated_line" ]; then
  now_epoch=$(date -u +%s)
  upd_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$updated_line" +%s 2>/dev/null)
  if [ -z "$upd_epoch" ]; then
    upd_epoch=$(date -d "$updated_line" +%s 2>/dev/null)
  fi
  if [ -n "$upd_epoch" ]; then
    age_days=$(( (now_epoch - upd_epoch) / 86400 ))
    if [ "$age_days" -ge 1 ]; then
      age_note="

STALE FLAG: this file was last written ${age_days} day(s) ago. Treat the Next line as
a lead, not a fact — confirm it against the current diff/branch before acting on it."
    fi
  fi
fi

compact_note=""
if [ "$source" = "compact" ]; then
  compact_note="

Context was just compacted (source=compact). The summary you now have may be lossier
than what produced this file. If what you now know differs from this file, rewrite it
before doing anything else."
fi

msg="Session state file for this project ($mainrepo):

${body}${age_note}${compact_note}

Rule: if the user's first message is state-seeking (\"what's next\", \"where are we\",
\"status\", or no message at all) — your first line must be this file's Next value,
verbatim, unless the STALE FLAG above says otherwise. If the user opens with an
unrelated task, follow the task instead; don't force this in."

jq -Rsn --arg event SessionStart --arg m "$msg" \
  '{hookSpecificOutput:{hookEventName:$event, additionalContext:$m}}' 2>/dev/null || true
exit 0
