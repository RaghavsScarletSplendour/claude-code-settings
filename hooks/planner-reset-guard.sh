#!/bin/sh
# Refuse to let any Claude session run the Neo Planner data reset.
#
# scripts/local/reset-data.sh (and its reset_data.py) destroy every row and
# every attachment in the planner deployment, irreversibly. They are a human
# operator tool, run once, by hand, from a real terminal. No agent should
# invoke them -- not while exploring, not while "verifying", not on request.
#
# Matches the stem anywhere in the command -- not just `name.sh`/`name.py` --
# so `bash x/reset-data.sh`, `python .../reset_data.py`, `cd foo &&
# ./reset-data.sh` and glob forms like `./reset-data*.sh` are all caught.
# It over-blocks harmless reads of these files by design: use Read/Grep.
set -eu

command=$(cat | jq -r '.tool_input.command // ""' 2>/dev/null || printf '')

if printf '%s' "$command" | grep -qE 'reset[-_]data'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: this command runs the Neo Planner data reset, which permanently destroys every task, user, message and attachment in the target deployment. It is a one-time human-operator tool and must never be run by a Claude session -- including for testing or verification. Tell the user to run it themselves from their own terminal, and do not attempt another route to the same effect."}}
JSON
fi

exit 0
