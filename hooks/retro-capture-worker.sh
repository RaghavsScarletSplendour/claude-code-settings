#!/usr/bin/env bash
# Does the actual work for retro-capture-auto.sh: extracts a session's
# genuine text and asks a small, cheap model to write a digest to
# ~/.claude/retro/<week>.md. Split into its own file and always launched
# detached (nohup + disown, see retro-capture-auto.sh) because the nested
# `claude -p` call below cannot finish inside SessionEnd's shared 1.5s
# default timeout, so it must run free of the dispatching hook's lifetime.
#
# No tool permissions needed here — this is a pure text-in/text-out call, so
# nothing in this script can touch files other than the append at the end.
set -uo pipefail

transcript="${1:?usage: retro-capture-worker.sh <transcript-path>}"
[ -f "$transcript" ] || exit 0

extracted=$(jq -r '
  select(.type=="user" or .type=="assistant")
  | select(.isMeta != true)
  | .message.content
  | if type=="array" then ([.[] | select(.type=="text") | .text] | join("\n")) else empty end
' "$transcript" 2>/dev/null | grep -vE '^(Base directory for this skill:|# /|Review target:|<|This session is being continued|Review this change for security vulnerabilities)')

# Skip trivial/near-empty sessions — not worth a digest entry.
turns=$(printf '%s' "$extracted" | grep -c .)
[ "${turns:-0}" -ge 6 ] || exit 0

week_file="$HOME/.claude/retro/$(date -u +%G)-W$(date -u +%V).md"
mkdir -p "$HOME/.claude/retro"

prompt="Below is extracted text (human + assistant turns) from one Claude Code session. Write ONLY a markdown digest, nothing else, in this exact shape:

## $(date -u +%Y-%m-%d) — <one-line title of what the session was about>
- Goal: <what was set out to do> — Shipped / Partial / Didn't ship
- Approach: <key decisions / final approach, 1-2 lines>
- Struggled:
  - <specific friction point> -> missing: <skill/hook/tool/context that would fix it>

If nothing genuinely struggled, write exactly 'Struggled: Nothing notable.' instead of inventing friction. Be concise, skip anything that went smoothly. Output nothing but the digest itself.

TRANSCRIPT TEXT:
$(printf '%s' "$extracted" | head -c 60000)"

digest=$(RETRO_CAPTURE_AUTO_RUNNING=1 claude -p --model claude-haiku-4-5-20251001 "$prompt" 2>/dev/null)

[ -n "$digest" ] && printf '\n%s\n' "$digest" >> "$week_file"
exit 0
