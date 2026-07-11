#!/usr/bin/env bash
# Warn-only PreToolUse reminder — creating a new utility/abstraction, or hand-rolling a
# mechanism a mature library already solves, should trigger the search-first skill first.
#
# TUNED AGAINST REAL DATA (W28 retro), because the obvious designs were spam:
#   - fire on any new source file          -> 127 fires/wk. Useless.
#   - grep content for mechanism keywords  ->  42 fires/wk, 34 of them the word "cache"
#                                              appearing incidentally inside TEST files. Useless.
#   - grep the user's prompt for intent    ->  28 fires/wk, ~0 true positives (matched pasted
#                                              file paths and context dumps). Useless.
#   - THIS (new non-test util/lib module, or a TIGHT mechanism list) -> ~2 fires/wk.
# A hook that cries wolf trains the model to ignore hook context, which is worse than no hook.
# Keep this narrow. If you widen the keyword list, re-measure the fire rate first.
#
# Never blocks: exit 0.
set -uo pipefail
input=$(cat)

path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
[ -n "$path" ] || exit 0

# Source files only.
printf '%s' "$path" | grep -qE '\.(py|ts|tsx|js|jsx|go|rb|rs)$' || exit 0
# Never on tests — that is where the false positives lived.
printf '%s' "$path" | grep -qEi '(^|/)(tests?|__tests__|e2e|spec)/|(^|/)test_|\.(test|spec)\.' && exit 0
# Only NEW files. Editing an existing module is not the moment search-first is about.
[ -e "$path" ] && exit 0

reason=""
# (a) a new utility/abstraction module — CLAUDE.md's literal trigger
if printf '%s' "$path" | grep -qEi '(^|/)(utils?|lib|helpers?|common|shared)/'; then
  reason="a new utility/abstraction module"
fi
# (b) hand-rolling a mechanism with a well-known library answer. Deliberately tight.
if [ -z "$reason" ]; then
  body=$(printf '%s' "$input" | jq -r '.tool_input.content // ""' 2>/dev/null | head -c 6000)
  if printf '%s' "$body" | grep -qEi 'rate[_ -]?limit|token[_ -]?bucket|leaky[_ -]?bucket|exponential[_ -]?backoff|levenshtein|edit[_ -]?distance|fuzzy[_ -]?match|hmac|verify[_ -]?signature|constant[_ -]?time[_ -]?compare|parse[_ -]?csv|csv[_ -]?pars|slugify|memoiz|lru[_ -]?cache|debounce|deep[_ -]?(merge|clone|equal)|bcrypt|password[_ -]?hash|job[_ -]?queue|task[_ -]?queue'; then
    reason="a mechanism mature libraries already solve (rate limiting, retries, fuzzy matching, HMAC, CSV/date parsing, queues, memoization, …)"
  fi
fi
[ -n "$reason" ] || exit 0

jq -cn --arg p "$path" --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:("Reminder: you are creating " + $r + " at " + $p + ". Per CLAUDE.md, run the search-first skill BEFORE writing it: check repo helper -> stdlib -> installed dependency -> maintained library/MCP/skill, and say what you ruled out. Only write custom code once that search comes up short.")}}'
exit 0
