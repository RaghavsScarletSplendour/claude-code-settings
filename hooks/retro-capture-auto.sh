#!/usr/bin/env bash
# SessionEnd hook — auto-run retro-capture so every session's digest lands in
# ~/.claude/retro/<week>.md without anyone remembering to type /retro-capture.
# Retro W29-30/W30-31/W32/W35 all flagged this as never wired.
#
# This script only dispatches. SessionEnd hooks share ONE 1.5-second default
# timeout across every SessionEnd hook registered (raised only by an explicit
# "timeout" key in settings.json). The actual work — a nested `claude -p`
# call — needs a real process start, a network round trip, and generation,
# none of which fits in 1.5s. So the work itself lives in
# retro-capture-worker.sh, launched detached (nohup + disown) below: this
# script exits almost immediately regardless of the timeout budget, and the
# worker keeps running after it's gone.
set -uo pipefail

# Recursion guard. The worker spawns its own `claude -p` call; that spawned
# process is itself a Claude Code session whose own SessionEnd would otherwise
# re-trigger this same hook, recursing with no depth limit. The worker sets
# this env var right before the spawn and the child inherits it, so the
# child's own run of this dispatcher exits here instead.
[ -n "${RETRO_CAPTURE_AUTO_RUNNING:-}" ] && exit 0

# The continuous-learning observer sets these on its own spawned sessions
# specifically to suppress non-essential hooks (see
# skills/continuous-learning-v2/hooks/observe.sh, which checks the same two
# vars). Without this check, every one of the observer's Haiku `--print`
# runs would get its own fabricated "session digest" here too — and those
# runs outnumber real sessions roughly 3:1 (see weekly-retro/SKILL.md), so
# the retro archive itself becomes the thing that needs cleaning.
[ "${ECC_HOOK_PROFILE:-standard}" = "minimal" ] && exit 0
[ "${ECC_SKIP_OBSERVE:-0}" = "1" ] && exit 0

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

nohup bash "$HOME/.claude/hooks/retro-capture-worker.sh" "$transcript" </dev/null >/dev/null 2>&1 &
disown
exit 0
