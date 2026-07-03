#!/usr/bin/env bash
# Warn-only PreToolUse reminder — nudges to invoke the claude-in-chrome preflight
# skill before driving mcp__claude-in-chrome__* browser tools. Fires ONCE per
# session (sentinel keyed by session_id). Never blocks: emits additionalContext, exit 0.
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
sentinel="${TMPDIR:-/tmp}/claude-cic-preflight-${sid}"
[ -f "$sentinel" ] && exit 0
: > "$sentinel" 2>/dev/null || true
jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"Reminder (once/session): invoke the claude-in-chrome preflight skill via the Skill tool before driving mcp__claude-in-chrome__* tools — it confirms the extension is connected + site permissions and batch-loads browser tools, avoiding mid-task blockers."}}'
exit 0
