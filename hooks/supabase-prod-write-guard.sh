#!/usr/bin/env bash
# PreToolUse GUARD (blocking) — the escalation of the warn-only supabase-write-reminder.
#
# WHY: In session a74315bd (W29), the warn-only reminder fired PRE-write on a prod
# execute_sql `BEGIN; DELETE FROM administration_compliance_items ...; INSERT ...`
# against ref lzyvawfyrisuyikjsgtk (prod), and the agent executed it on prod anyway
# without spawning database-reviewer. Verified against source: the write went through
# mcp__claude_ai_Supabase__execute_sql — the exact tool this matches. A warn-only hook
# on an IRREVERSIBLE prod write is ignorable prose with a shell wrapper. This one denies.
#
# SCOPE: only hard-stops WRITES/DDL/migrations against the PROD ref. Staging and every
# other ref keep the existing warn-only reminder — this is not a blanket block.
#
# OVERRIDE: the human sets CLAUDE_PROD_WRITE_OK=1 (env) or touches ~/.claude/.prod-write-ok
# for the next 5 min after they have (a) seen database-reviewer's verdict and (b) approved.
set -uo pipefail

PROD_REF="lzyvawfyrisuyikjsgtk"   # jdjones-agents = PROD (names mislead)
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
ref=$(printf '%s' "$input" | jq -r '.tool_input.project_id // .tool_input.project_ref // ""' 2>/dev/null)

is_prod_write=0
case "$tool" in
  *apply_migration) [ "$ref" = "$PROD_REF" ] && is_prod_write=1 ;;
  *execute_sql)
    if [ "$ref" = "$PROD_REF" ]; then
      q=$(printf '%s' "$input" | jq -r '.tool_input.query // .tool_input.sql // ""' 2>/dev/null)
      printf '%s' "$q" | grep -iqE '\b(insert|update|delete|drop|alter|create|truncate|grant|revoke)\b' && is_prod_write=1
    fi ;;
esac
[ "$is_prod_write" = 1 ] || exit 0

# Override: env flag, or a fresh sentinel file (< 5 min old)
if [ "${CLAUDE_PROD_WRITE_OK:-0}" = "1" ]; then exit 0; fi
sentinel="$HOME/.claude/.prod-write-ok"
if [ -f "$sentinel" ]; then
  age=$(( $(date +%s) - $(stat -f %m "$sentinel" 2>/dev/null || echo 0) ))
  [ "$age" -lt 300 ] && exit 0
fi

# DENY. Route to the human instead of executing an irreversible prod write autonomously.
jq -cn '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "BLOCKED: irreversible WRITE against PROD (lzyvawfyrisuyikjsgtk). This is not a reminder you can proceed past. Required before this can run: (1) spawn database-reviewer and show its verdict (WHERE-scope, revert safety, lock order); (2) get the human to explicitly approve; (3) they set CLAUDE_PROD_WRITE_OK=1 or `touch ~/.claude/.prod-write-ok`. Prefer applying to staging (ffrsffycrpevjhfyklxs) first and having the human run the prod apply themselves."
  }
}'
exit 0

# NOTE (install/test): wire via the update-config skill on the PreToolUse
# `mcp__claude_ai_Supabase__apply_migration|mcp__claude_ai_Supabase__execute_sql` matcher,
# BEFORE the existing warn-only reminder. Test like W28's 5/5 pass:
#  - prod-ref DELETE  -> denied
#  - prod-ref apply_migration -> denied
#  - staging-ref DELETE -> NOT denied (falls through to warn-only)
#  - prod-ref SELECT (read) -> NOT denied
#  - override present -> allowed
# Confirm the running Claude Code build honors permissionDecision:"deny" on MCP tools; if a
# given build only supports exit-code-2 blocking, swap the JSON for `exit 2` + stderr reason.
